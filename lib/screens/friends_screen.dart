import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/pieces.dart';

/// The Friends destination: requests to answer, people you may know, and
/// your friends.
///
/// A desktop shows each person as a card with their photo, in a grid that
/// takes as many columns as fit; a phone shows rows, a portrait beside two
/// buttons.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

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
          final requests = session.incomingRequests;
          final suggestions = session.suggestions;
          final friends = session.friends;
          return UnaColumn(
            gap: GapSize.xl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (theme.isPhone) Gap.raw(theme.gap(GapSize.xs)),
              const PageTitle(
                'Friends',
                subtitle: 'Answer requests and find people you know.',
              ),
              _Section(
                title: 'Friend requests',
                count: requests.length,
                empty: const Empty(
                  icon: PhosphorIcon(PhosphorIconsRegular.userCheck),
                  title: Text('No new requests'),
                  description: Text(
                    'When someone asks to be your friend, they show up here.',
                  ),
                ),
                people: requests,
                builder: (person) => _PersonCard(
                  person: person,
                  primaryLabel: 'Confirm',
                  onPrimary: () {
                    session.confirm(person);
                    showSocialToast(
                      context,
                      'You and ${person.firstName} are now friends',
                      variant: ToastVariant.success,
                    );
                  },
                  secondaryLabel: 'Delete',
                  onSecondary: () {
                    session.decline(person);
                    showSocialToast(
                      context,
                      'Request deleted',
                      actionLabel: 'Undo',
                      onAction: () =>
                          session.restore(person, Friendship.incoming),
                    );
                  },
                ),
              ),
              _Section(
                title: 'People you may know',
                people: suggestions,
                empty: const Empty(
                  icon: PhosphorIcon(PhosphorIconsRegular.usersThree),
                  title: Text('That is everyone for now'),
                  description: Text('Check back later for new suggestions.'),
                ),
                builder: (person) {
                  final requested =
                      session.friendshipWith(person) == Friendship.requested;
                  return _PersonCard(
                    person: person,
                    primaryLabel: requested ? 'Requested' : 'Add friend',
                    primaryIcon: requested
                        ? PhosphorIconsFill.userCheck
                        : PhosphorIconsFill.userPlus,
                    primaryTonal: requested,
                    onPrimary: () => requested
                        ? session.cancelRequest(person)
                        : session.addFriend(person),
                    secondaryLabel: 'Remove',
                    onSecondary: () {
                      session.dismissSuggestion(person);
                      showSocialToast(
                        context,
                        '${person.firstName} removed from suggestions',
                        actionLabel: 'Undo',
                        onAction: () =>
                            session.restore(person, Friendship.none),
                      );
                    },
                  );
                },
              ),
              _AllFriends(friends: friends),
              const Gap.md(),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.people,
    required this.builder,
    required this.empty,
    this.count,
  });

  final String title;
  final int? count;
  final List<Person> people;
  final Widget Function(Person person) builder;
  final Widget empty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeading(
          title,
          action: count == null || count == 0
              ? null
              : Badge(child: Text('$count new')),
        ),
        const Gap.md(),
        if (people.isEmpty)
          Card(child: empty)
        else if (theme.isPhone)
          Card(
            style: CardTheme(padding: EdgeInsets.all(theme.gap(GapSize.md))),
            child: UnaColumn(
              gap: GapSize.lg,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final person in people)
                  KeyedSubtree(
                    key: ValueKey(person.id),
                    child: Entrance(child: builder(person)),
                  ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final gap = theme.gap(GapSize.md);
              final columns = (constraints.maxWidth / 220).floor().clamp(2, 5);
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final person in people)
                    SizedBox(
                      key: ValueKey(person.id),
                      width: width,
                      child: Entrance(child: builder(person)),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

/// A person with two answers: a card with their photo on a desktop, a row
/// on a phone.
class _PersonCard extends StatelessWidget {
  const _PersonCard({
    required this.person,
    required this.primaryLabel,
    required this.onPrimary,
    required this.secondaryLabel,
    required this.onSecondary,
    this.primaryIcon,
    this.primaryTonal = false,
  });

  final Person person;
  final String primaryLabel;
  final IconData? primaryIcon;
  final bool primaryTonal;
  final VoidCallback onPrimary;
  final String secondaryLabel;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A phone's row has half its width for each answer: the label, not
    // an icon, says what the button does.
    final icon = primaryIcon == null || theme.isPhone
        ? null
        : PhosphorIcon(primaryIcon!);
    final primary = primaryTonal
        ? Button.secondary(
            leading: icon,
            onPressed: onPrimary,
            child: ButtonLabel(primaryLabel),
          )
        : Button(
            leading: icon,
            onPressed: onPrimary,
            child: ButtonLabel(primaryLabel),
          );
    final secondary = Button.secondary(
      onPressed: onSecondary,
      child: ButtonLabel(secondaryLabel),
    );
    final name = Text(
      person.name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.large.copyWith(color: scheme.foreground),
    );
    final mutual = Row(
      children: [
        AvatarGroup(
          size: 18,
          children: [
            for (final friend in People.friends.take(2))
              Image.asset(friend.photo, fit: BoxFit.cover),
          ],
        ),
        const Gap.xs(),
        Flexible(
          child: Text(
            '${person.mutual} mutual friends',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.caption,
          ),
        ),
      ],
    );

    if (theme.isPhone) {
      return Row(
        children: [
          Pressable(
            onPressed: () => openProfile(context, person),
            semanticLabel: person.name,
            builder: (context, states) => PersonAvatar(person, size: 76),
          ),
          const Gap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                name,
                const SizedBox(height: 2),
                mutual,
                const Gap.sm(),
                Row(
                  spacing: theme.gap(GapSize.sm),
                  children: [
                    Expanded(child: primary),
                    Expanded(child: secondary),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Card(
      style: const CardTheme(padding: EdgeInsets.zero),
      onTap: () => openProfile(context, person),
      semanticLabel: person.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Photo(
            person.photo,
            aspectRatio: 1,
            borderRadius: BorderRadius.vertical(top: theme.radii.xl.topLeft),
          ),
          Padding(
            padding: EdgeInsets.all(theme.gap(GapSize.md)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                name,
                const SizedBox(height: 2),
                mutual,
                const Gap.md(),
                primary,
                const Gap.sm(),
                secondary,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllFriends extends StatefulWidget {
  const _AllFriends({required this.friends});

  final List<Person> friends;

  @override
  State<_AllFriends> createState() => _AllFriendsState();
}

class _AllFriendsState extends State<_AllFriends> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = widget.friends
        .where(
          (person) => person.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeading(
          'All friends',
          subtitle: '${widget.friends.length} friends',
          action: theme.isPhone
              ? null
              : SizedBox(
                  width: 240,
                  child: SearchField(
                    placeholder: const Text('Search friends'),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
        ),
        if (theme.isPhone) ...[
          const Gap.md(),
          SearchField(
            placeholder: const Text('Search friends'),
            onChanged: (value) => setState(() => _query = value),
          ),
        ],
        const Gap.md(),
        if (shown.isEmpty)
          Card(
            child: Empty(
              icon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass),
              title: const Text('No friends match'),
              description: Text('Nobody called "$_query" yet.'),
            ),
          )
        else
          ListSection(
            children: [
              for (final person in shown)
                ListTile(
                  leading: PersonAvatar(person, showOnline: true),
                  title: Text(person.name),
                  subtitle: Text(
                    person.online
                        ? 'Active now'
                        : '${person.work} · ${person.city}',
                  ),
                  showChevron: true,
                  onTap: () => openProfile(context, person),
                ),
            ],
          ),
      ],
    );
  }
}
