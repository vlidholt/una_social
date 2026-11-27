import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/pieces.dart';
import 'package:una_social/widgets/post_card.dart';

/// Opens [group]'s page over the shell.
Future<void> openGroup(BuildContext context, Group group) =>
    context.pushPage<void>((context) => GroupPage(group));

/// The Groups destination: your groups, the latest from them, and groups
/// to discover.
class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.social;
    return PageContainer(
      scrollable: true,
      maxWidth: 1080,
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final mine = session.myGroups;
          final discover = Groups.all
              .where((group) => !session.isMember(group))
              .toList();
          final posts = session.feed
              .where(
                (post) => post.group != null && session.isMember(post.group!),
              )
              .toList();
          final feed = UnaColumn(
            gap: GapSize.lg,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionHeading('Recent activity'),
              if (posts.isEmpty)
                const Card(
                  child: Empty(
                    icon: PhosphorIcon(PhosphorIconsRegular.usersFour),
                    title: Text('Nothing new from your groups'),
                    description: Text('Join a group to see its posts here.'),
                  ),
                )
              else
                for (final post in posts)
                  PostCard(post, key: ValueKey(post.id)),
            ],
          );
          final discoverSection = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionHeading(
                'Discover',
                subtitle: 'Suggested for you',
              ),
              const Gap.md(),
              if (discover.isEmpty)
                const Card(
                  child: Empty(
                    icon: PhosphorIcon(PhosphorIconsRegular.compass),
                    title: Text('You have joined them all'),
                    description: Text('New groups are suggested every week.'),
                  ),
                )
              else
                UnaColumn(
                  gap: GapSize.md,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final group in discover)
                      Entrance(
                        key: ValueKey(group.id),
                        child: GroupCard(group),
                      ),
                  ],
                ),
            ],
          );

          return UnaColumn(
            gap: GapSize.xl,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (theme.isPhone) Gap.raw(theme.gap(GapSize.xs)),
              PageTitle(
                'Groups',
                subtitle: 'Your communities, all in one place.',
                actions: [
                  if (!theme.isPhone)
                    Button(
                      leading: const PhosphorIcon(PhosphorIconsBold.plus),
                      onPressed: () => _createGroup(context),
                      child: const Text('Create group'),
                    ),
                ],
              ),
              _YourGroups(groups: mine),
              if (theme.isPhone) ...[
                discoverSection,
                feed,
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: theme.gap(GapSize.xl),
                  children: [
                    Expanded(child: feed),
                    SizedBox(width: 380, child: discoverSection),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  static void _createGroup(BuildContext context) => showSocialToast(
    context,
    'Group drafts are coming soon',
    description: 'For now, join one of the groups suggested for you.',
  );
}

/// Your groups in a strip of covers that scrolls sideways.
class _YourGroups extends StatelessWidget {
  const _YourGroups({required this.groups});

  final List<Group> groups;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (groups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SectionHeading('Your groups', subtitle: '${groups.length} groups'),
        const Gap.md(),
        SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: groups.length,
            separatorBuilder: (context, index) => const Gap.md(),
            itemBuilder: (context, index) {
              final group = groups[index];
              return SizedBox(
                width: 220,
                child: Pressable(
                  onPressed: () => openGroup(context, group),
                  semanticLabel: group.name,
                  builder: (context, states) => ClipRRect(
                    borderRadius: theme.radii.xl,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AnimatedScale(
                          scale: states.contains(WidgetState.hovered)
                              ? 1.05
                              : 1,
                          duration: Motion.of(context).normal,
                          curve: Motion.of(context).standard,
                          child: RevealImage.asset(
                            group.cover,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x00000000), Color(0xCC000000)],
                              stops: [.35, 1],
                            ),
                          ),
                        ),
                        PositionedDirectional(
                          start: 14,
                          end: 14,
                          bottom: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                group.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.large.copyWith(
                                  color: const Color(0xFFFFFFFF),
                                ),
                              ),
                              Text(
                                '${group.postsPerDay} new posts today',
                                style: theme.textTheme.caption.copyWith(
                                  color: const Color(0xD9FFFFFF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A group to join: its cover beside its name, size and Join.
class GroupCard extends StatelessWidget {
  const GroupCard(this.group, {super.key});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = context.social;
    final member = session.isMember(group);
    return Card(
      style: CardTheme(padding: EdgeInsets.all(theme.gap(GapSize.md))),
      onTap: () => openGroup(context, group),
      semanticLabel: group.name,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 64,
            child: Photo(group.cover, borderRadius: theme.radii.lg),
          ),
          const Gap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small.copyWith(
                    color: scheme.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${group.private ? 'Private' : 'Public'} · ${group.members} members',
                  style: theme.textTheme.caption,
                ),
              ],
            ),
          ),
          const Gap.sm(),
          member
              ? Button.secondary(
                  size: ButtonSize.sm,
                  onPressed: () => session.toggleMembership(group),
                  child: const Text('Joined'),
                )
              : Button(
                  size: ButtonSize.sm,
                  onPressed: () {
                    session.toggleMembership(group);
                    showSocialToast(
                      context,
                      group.private
                          ? 'Request sent to ${group.name}'
                          : 'Welcome to ${group.name}',
                      variant: ToastVariant.success,
                    );
                  },
                  child: Text(group.private ? 'Request' : 'Join'),
                ),
        ],
      ),
    );
  }
}

/// A group's own page: the cover, the name and members, Join, the about
/// and its posts.
class GroupPage extends StatelessWidget {
  const GroupPage(this.group, {super.key});

  final Group group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = context.social;
    final phone = theme.isPhone;
    return Scaffold(
      appBar: AppBar(
        surfaceBehavior: AppBarSurfaceBehavior.whenScrolled,
        title: Text(group.name),
      ),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final member = session.isMember(group);
          final posts = session.feed
              .where((post) => post.group == group)
              .toList();
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height:
                      (phone ? 220 : 320) +
                      MediaQuery.paddingOf(context).top * (phone ? 1 : 0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      RevealImage.asset(group.cover, fit: BoxFit.cover),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              scheme.background.withValues(alpha: 0),
                              scheme.background,
                            ],
                            stops: const [.55, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: theme.margin),
                      child: UnaColumn(
                        gap: GapSize.lg,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                group.name,
                                style: theme.textTheme.h2.copyWith(
                                  color: scheme.foreground,
                                ),
                              ),
                              const Gap.xs(),
                              Row(
                                children: [
                                  PhosphorIcon(
                                    group.private
                                        ? PhosphorIconsFill.lockSimple
                                        : PhosphorIconsFill.globeHemisphereWest,
                                    size: 14,
                                    color: scheme.mutedForeground,
                                  ),
                                  const Gap.xs(),
                                  Flexible(
                                    child: Text(
                                      '${group.private ? 'Private' : 'Public'} group · ${group.members} members',
                                      style: theme.textTheme.muted,
                                    ),
                                  ),
                                ],
                              ),
                              const Gap.md(),
                              Row(
                                children: [
                                  AvatarGroup(
                                    size: 30,
                                    children: [
                                      for (final person in People.friends.take(
                                        5,
                                      ))
                                        Image.asset(
                                          person.photo,
                                          fit: BoxFit.cover,
                                        ),
                                    ],
                                  ),
                                  const Spacer(),
                                  member
                                      ? Button.secondary(
                                          leading: const PhosphorIcon(
                                            PhosphorIconsFill.userCheck,
                                          ),
                                          onPressed: () =>
                                              session.toggleMembership(group),
                                          child: const ButtonLabel('Joined'),
                                        )
                                      : Button(
                                          leading: const PhosphorIcon(
                                            PhosphorIconsFill.userPlus,
                                          ),
                                          onPressed: () =>
                                              session.toggleMembership(group),
                                          child: ButtonLabel(
                                            group.private
                                                ? 'Request to join'
                                                : 'Join group',
                                          ),
                                        ),
                                ],
                              ),
                            ],
                          ),
                          Card(
                            title: const Text('About'),
                            child: Text(
                              group.about,
                              style: theme.textTheme.p.copyWith(
                                color: scheme.foreground,
                              ),
                            ),
                          ),
                          if (posts.isEmpty)
                            Card(
                              child: Empty(
                                icon: const PhosphorIcon(
                                  PhosphorIconsRegular.chatsCircle,
                                ),
                                title: const Text('Be the first to post'),
                                description: Text(
                                  'Start a conversation in ${group.name}.',
                                ),
                              ),
                            )
                          else
                            for (final post in posts)
                              PostCard(post, key: ValueKey(post.id)),
                          SizedBox(
                            height: MediaQuery.paddingOf(context).bottom,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
