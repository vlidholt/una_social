import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/composer.dart';
import 'package:una_social/widgets/pieces.dart';
import 'package:una_social/widgets/post_card.dart';
import 'package:una_social/widgets/side_columns.dart';
import 'package:una_social/widgets/stories.dart';

/// The Home destination: the feed.
///
/// * **Desktop** — three columns: your shortcuts and groups on the start
///   side, the feed in the middle, birthdays and contacts on the end side.
///   The side columns leave as the window narrows, the contacts first.
/// * **Phone** — one column: the composer, the stories strip and the
///   posts, pulled down to refresh.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// The feed is "fetched" when the screen first shows: skeletons stand in
  /// for a moment, as they would over a network.
  bool _loading = true;
  Timer? _timer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The posts' photos load while the skeletons stand in, so the feed
    // arrives with its pictures; the stories' photos are what the story
    // viewer opens on.
    if (_precached) return;
    _precached = true;
    precachePhotos(context, [
      for (final post in context.social.feed) ...post.photos,
      for (final story in Stories.all) story.photo,
    ]);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() =>
      Future<void>.delayed(const Duration(milliseconds: 1200));

  @override
  Widget build(BuildContext context) {
    final feed = _Feed(loading: _loading);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FormFactorBuilder(
        mobile: (context) => PageContainer(
          scrollable: true,
          padding: EdgeInsets.symmetric(
            vertical: Theme.of(context).gap(GapSize.md),
          ),
          child: feed,
        ),
        desktop: (context) => _DesktopColumns(feed: feed),
      ),
    );
  }
}

class _DesktopColumns extends StatelessWidget {
  const _DesktopColumns({required this.feed});

  final Widget feed;

  static const _startWidth = 280.0;
  static const _endWidth = 300.0;
  static const _feedWidth = 600.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gap = theme.gap(GapSize.xl);
    final page = (theme.layoutTheme.pagePadding ?? const EdgeInsets.all(24))
        .resolve(Directionality.of(context));
    final insets = MediaQuery.paddingOf(context);

    // Each column scrolls on its own, under the bar, as the page did: the
    // side columns stay where they are while the feed moves.
    Widget column(Widget child, {bool primary = false}) =>
        SingleChildScrollView(
          primary: primary,
          padding: EdgeInsets.only(
            top: insets.top + page.top,
            bottom: insets.bottom + page.bottom,
          ),
          child: child,
        );

    return Padding(
      padding: EdgeInsets.only(left: page.left, right: page.right),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1440),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final showEnd =
                  width >= _feedWidth + _endWidth + _startWidth + gap * 2;
              final showStart = width >= _feedWidth + _startWidth * .9 + gap;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: [
                  if (showStart)
                    SizedBox(
                      key: const ValueKey('start'),
                      width: _startWidth,
                      child: column(const ShortcutsColumn()),
                    ),
                  Expanded(
                    key: const ValueKey('feed'),
                    child: column(
                      primary: true,
                      Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: _feedWidth,
                          ),
                          child: feed,
                        ),
                      ),
                    ),
                  ),
                  if (showEnd)
                    SizedBox(
                      key: const ValueKey('end'),
                      width: _endWidth,
                      child: column(const ContactsColumn()),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Feed extends StatelessWidget {
  const _Feed({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = theme.isPhone;
    final inset = EdgeInsets.symmetric(horizontal: phone ? theme.margin : 0);
    return ListenableBuilder(
      listenable: context.social,
      builder: (context, _) {
        final posts = context.social.feed;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: theme.gap(phone ? GapSize.md : GapSize.lg),
          children: [
            if (phone) ...[
              Padding(padding: inset, child: const ComposerCard()),
              const StoriesRow(),
            ] else ...[
              const StoriesRow(),
              const ComposerCard(),
            ],
            if (loading)
              for (var i = 0; i < 2; i++)
                Padding(padding: inset, child: const PostSkeleton())
            else if (posts.isEmpty)
              Padding(
                padding: inset,
                child: Card(
                  child: Empty(
                    icon: const PhosphorIcon(PhosphorIconsRegular.sparkle),
                    title: const Text('You are all caught up'),
                    description: const Text(
                      'Add friends or join groups to see more posts here.',
                    ),
                  ),
                ),
              )
            else
              for (final post in posts)
                Padding(
                  key: ValueKey(post.id),
                  padding: inset,
                  child: Entrance(child: PostCard(post)),
                ),
            if (!loading && posts.isNotEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: theme.gap(GapSize.lg)),
                child: Column(
                  children: [
                    PhosphorIcon(
                      PhosphorIconsFill.checkCircle,
                      size: 28,
                      color: theme.colorScheme.tint,
                    ),
                    const Gap.sm(),
                    Text(
                      'You are all caught up',
                      style: theme.textTheme.large.copyWith(
                        color: theme.colorScheme.foreground,
                      ),
                    ),
                    Text(
                      'You have seen every new post from the last 3 days.',
                      style: theme.textTheme.muted,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A post's shape in skeletons, while the feed loads.
class PostSkeleton extends StatelessWidget {
  const PostSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Skeleton(
                width: theme.avatarMd,
                height: theme.avatarMd,
                borderRadius: theme.radii.full,
              ),
              const Gap.sm(),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Skeleton(width: 140, height: 12),
                  Gap.xs(),
                  Skeleton(width: 80, height: 10),
                ],
              ),
            ],
          ),
          const Gap.md(),
          const Skeleton(width: double.infinity, height: 12),
          const Gap.xs(),
          const Skeleton(width: 220, height: 12),
          const Gap.md(),
          Skeleton(
            width: double.infinity,
            height: 220,
            borderRadius: theme.radii.lg,
          ),
        ],
      ),
    );
  }
}
