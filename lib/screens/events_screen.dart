import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/pieces.dart';

enum _EventFilter { upcoming, going, interested }

/// The Events destination: what is on near you, and what you said you
/// would go to.
class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  _EventFilter _filter = _EventFilter.upcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.social;
    return PageContainer(
      scrollable: true,
      maxWidth: 1180,
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final events = Events.all.where((event) {
            final rsvp = session.rsvpOf(event);
            return switch (_filter) {
              _EventFilter.upcoming => true,
              _EventFilter.going => rsvp == Rsvp.going,
              _EventFilter.interested => rsvp == Rsvp.interested,
            };
          }).toList();
          return UnaColumn(
            gap: GapSize.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (theme.isPhone) Gap.raw(theme.gap(GapSize.xs)),
              const PageTitle('Events', subtitle: 'Lisbon and nearby'),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SegmentedControl<_EventFilter>(
                  value: _filter,
                  expand: theme.isPhone,
                  onChanged: (value) => setState(() => _filter = value),
                  segments: const [
                    Segment(
                      value: _EventFilter.upcoming,
                      label: Text('Upcoming'),
                    ),
                    Segment(value: _EventFilter.going, label: Text('Going')),
                    Segment(
                      value: _EventFilter.interested,
                      label: Text('Interested'),
                    ),
                  ],
                ),
              ),
              if (events.isEmpty)
                Card(
                  child: Empty(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.calendarBlank,
                    ),
                    title: Text(
                      _filter == _EventFilter.going
                          ? 'You are not going to anything yet'
                          : 'Nothing saved yet',
                    ),
                    description: const Text(
                      'Find something on the Upcoming tab and tap Going or Interested.',
                    ),
                    actions: [
                      Button.outline(
                        onPressed: () =>
                            setState(() => _filter = _EventFilter.upcoming),
                        child: const Text('See upcoming events'),
                      ),
                    ],
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = theme.gap(GapSize.md);
                    final columns = theme.isPhone
                        ? 1
                        : (constraints.maxWidth / 400).floor().clamp(1, 3);
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final event in events)
                          SizedBox(
                            key: ValueKey(event.id),
                            width: width,
                            child: Entrance(child: EventCard(event)),
                          ),
                      ],
                    );
                  },
                ),
              const Gap.md(),
            ],
          );
        },
      ),
    );
  }
}

/// An event: the picture with its date, what, when and where, who is
/// going, and Interested and Going.
class EventCard extends StatelessWidget {
  const EventCard(this.event, {super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = context.social;
    final rsvp = session.rsvpOf(event);
    final going = event.going + (rsvp == Rsvp.going ? 1 : 0);
    return Card(
      style: const CardTheme(padding: EdgeInsets.zero),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Photo(
                event.photo,
                aspectRatio: 16 / 9,
                borderRadius: BorderRadius.vertical(
                  top: theme.radii.xl.topLeft,
                ),
              ),
              PositionedDirectional(
                start: 12,
                top: 12,
                child: DateTile(month: event.month, day: event.day),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(theme.gap(GapSize.lg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.when.toUpperCase(),
                  style: theme.textTheme.caption.copyWith(
                    color: const Color(0xFFF43F5E),
                    fontWeight: FontWeight.w700,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.large.copyWith(
                    color: scheme.foreground,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.where,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted,
                ),
                const Gap.md(),
                Row(
                  children: [
                    AvatarGroup(
                      size: 24,
                      children: [
                        for (final person in People.friends.take(3))
                          Image.asset(person.photo, fit: BoxFit.cover),
                      ],
                    ),
                    const Gap.sm(),
                    Expanded(
                      child: ContentSwitch(
                        value: going,
                        child: Text(
                          '${compactCount(going)} going · ${compactCount(event.interested)} interested',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.caption,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap.md(),
                Row(
                  spacing: theme.gap(GapSize.sm),
                  children: [
                    Expanded(
                      child: rsvp == Rsvp.going
                          ? Button(
                              leading: const PhosphorIcon(
                                PhosphorIconsBold.check,
                              ),
                              onPressed: () =>
                                  session.setRsvp(event, Rsvp.none),
                              child: const ButtonLabel('Going'),
                            )
                          : Button.secondary(
                              leading: const PhosphorIcon(
                                PhosphorIconsRegular.checkCircle,
                              ),
                              onPressed: () {
                                session.setRsvp(event, Rsvp.going);
                                showSocialToast(
                                  context,
                                  'See you there!',
                                  description:
                                      '${event.title} is in your calendar.',
                                  variant: ToastVariant.success,
                                );
                              },
                              child: const ButtonLabel('Going'),
                            ),
                    ),
                    Expanded(
                      child: Button.secondary(
                        leading: PhosphorIcon(
                          rsvp == Rsvp.interested
                              ? PhosphorIconsFill.star
                              : PhosphorIconsRegular.star,
                          color: rsvp == Rsvp.interested
                              ? const Color(0xFFF59E0B)
                              : null,
                        ),
                        onPressed: () => session.setRsvp(
                          event,
                          rsvp == Rsvp.interested ? Rsvp.none : Rsvp.interested,
                        ),
                        child: const ButtonLabel('Interested'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
