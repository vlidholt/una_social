import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/pieces.dart';
import 'package:una_social/widgets/post_card.dart';

/// The Notifications destination: what happened, new first, each with a
/// badge for its kind. Opening one marks it read and goes to its subject.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _unreadOnly = false;

  void _open(Notice notice) {
    final session = context.social;
    session.markRead(notice);
    switch (notice.target) {
      case 'friends':
        context.goTo(Destination.friends);
      case 'events':
        context.goTo(Destination.events);
      case 'profile':
        openProfile(context, People.me);
      case 'birthday':
        session.openChatWith(notice.person!);
        context.goTo(Destination.messages);
      case final String id:
        final post = session.postById(id);
        if (post != null) {
          context.pushPage<void>(
            (context) => Scaffold(
              appBar: AppBar(title: Text('${post.author.firstName}\'s post')),
              body: PageContainer(
                scrollable: true,
                maxWidth: 680,
                child: PostCard(post),
              ),
            ),
          );
        }
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.social;
    return PageContainer(
      scrollable: true,
      maxWidth: 720,
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final notices = Notices.all
              .where((notice) => !_unreadOnly || !session.isRead(notice))
              .toList();
          final fresh = notices.where((notice) => !notice.earlier).toList();
          final earlier = notices.where((notice) => notice.earlier).toList();
          return UnaColumn(
            gap: GapSize.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (theme.isPhone) Gap.raw(theme.gap(GapSize.xs)),
              PageTitle(
                'Notifications',
                actions: [
                  Button.ghost(
                    onPressed: session.unreadNotices == 0
                        ? null
                        : session.markAllRead,
                    leading: const PhosphorIcon(PhosphorIconsRegular.checks),
                    child: const Text('Mark all read'),
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: SegmentedControl<bool>(
                  value: _unreadOnly,
                  onChanged: (value) => setState(() => _unreadOnly = value),
                  segments: const [
                    Segment(value: false, label: Text('All')),
                    Segment(value: true, label: Text('Unread')),
                  ],
                ),
              ),
              if (notices.isEmpty)
                const Card(
                  child: Empty(
                    icon: PhosphorIcon(PhosphorIconsRegular.bellSimple),
                    title: Text('You are all caught up'),
                    description: Text('New notifications will show up here.'),
                  ),
                ),
              if (fresh.isNotEmpty)
                _Group(title: 'New', notices: fresh, onOpen: _open),
              if (earlier.isNotEmpty)
                _Group(title: 'Earlier', notices: earlier, onOpen: _open),
              const Gap.md(),
            ],
          );
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.notices,
    required this.onOpen,
  });

  final String title;
  final List<Notice> notices;
  final ValueChanged<Notice> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: theme.textTheme.large.copyWith(
              color: theme.colorScheme.foreground,
            ),
          ),
        ),
        Card(
          style: const CardTheme(padding: EdgeInsets.all(6)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final notice in notices)
                _NoticeRow(notice, onOpen: () => onOpen(notice)),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoticeRow extends StatelessWidget {
  const _NoticeRow(this.notice, {required this.onOpen});

  final Notice notice;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = !context.social.isRead(notice);
    final size = theme.isPhone ? 52.0 : 56.0;
    final picture = notice.person != null
        ? PersonAvatar(notice.person!, size: size)
        : ClipOval(
            child: SizedBox.square(
              dimension: size,
              child: RevealImage.asset(notice.photo!, fit: BoxFit.cover),
            ),
          );
    return Pressable(
      onPressed: onOpen,
      semanticLabel: [
        if (unread) 'Unread.',
        notice.person?.name,
        notice.text,
        notice.age,
      ].whereType<String>().join(' '),
      builder: (context, states) => AnimatedFill(
        color: states.contains(WidgetState.hovered)
            ? scheme.foreground.withValues(alpha: .05)
            : unread
            ? scheme.accent.withValues(alpha: scheme.accent.a * .6)
            : scheme.foreground.withValues(alpha: 0),
        borderRadius: theme.radii.lg,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  picture,
                  PositionedDirectional(
                    end: -4,
                    bottom: -4,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: notice.kind.color,
                        border: Border.all(color: scheme.card, width: 2.5),
                      ),
                      child: PhosphorIcon(
                        notice.kind.icon,
                        size: 12,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap.md(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text.rich(
                      TextSpan(
                        children: [
                          if (notice.person != null)
                            TextSpan(
                              text: '${notice.person!.name} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          TextSpan(text: notice.text),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small.copyWith(
                        color: scheme.foreground,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notice.age,
                      style: theme.textTheme.caption.copyWith(
                        color: unread ? scheme.tint : null,
                        fontWeight: unread ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap.sm(),
              AnimatedOpacity(
                opacity: unread ? 1 : 0,
                duration: Motion.of(context).fast,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.tint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
