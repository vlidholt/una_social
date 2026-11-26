import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/widgets/composer.dart';
import 'package:una_social/widgets/pieces.dart';

/// The stories at the top of the feed: "Create story", then a card per
/// story. A row that fills the feed column on a desktop; a strip that
/// scrolls sideways, edge to edge, on a phone.
class StoriesRow extends StatelessWidget {
  const StoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = theme.isPhone;
    final cards = <Widget>[
      const _CreateStoryCard(),
      for (final (index, story) in Stories.all.indexed)
        _StoryCard(story: story, index: index),
    ];
    if (!phone) {
      return SizedBox(
        height: 200,
        child: Row(
          spacing: theme.gap(GapSize.sm),
          children: [
            for (final card in cards.take(5)) Expanded(child: card),
          ],
        ),
      );
    }
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        padding: EdgeInsets.symmetric(horizontal: theme.margin),
        itemCount: cards.length,
        separatorBuilder: (context, index) => const Gap.sm(),
        itemBuilder: (context, index) =>
            SizedBox(width: 104, child: cards[index]),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.story, required this.index});

  final Story story;
  final int index;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = theme.radii.xl;
    return Pressable(
      onPressed: () => openStories(context, index),
      semanticLabel: '${story.person.name}\'s story',
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return ClipRRect(
          borderRadius: radius,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: hovered ? 1.05 : 1,
                duration: Motion.of(context).normal,
                curve: Motion.of(context).standard,
                child: Image.asset(
                  story.photo,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x33000000),
                      Color(0x00000000),
                      Color(0xAA000000),
                    ],
                    stops: [0, .45, 1],
                  ),
                ),
              ),
              PositionedDirectional(
                start: 8,
                top: 8,
                child: PersonAvatar(story.person, size: 36, storyRing: true),
              ),
              PositionedDirectional(
                start: 10,
                end: 10,
                bottom: 10,
                child: Text(
                  story.person.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small.copyWith(
                    color: const Color(0xFFFFFFFF),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CreateStoryCard extends StatelessWidget {
  const _CreateStoryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Pressable(
      onPressed: () => showComposer(context, startWithPhoto: true),
      semanticLabel: 'Create story',
      builder: (context, states) => ClipRRect(
        borderRadius: theme.radii.xl,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.card,
            border: Border.all(color: scheme.border),
            borderRadius: theme.radii.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 7,
                child: Image.asset(
                  People.me.photo,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
              Expanded(
                flex: 3,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      top: -18,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: scheme.primary,
                          border: Border.all(color: scheme.card, width: 3),
                        ),
                        child: PhosphorIcon(
                          PhosphorIconsBold.plus,
                          size: 16,
                          color: scheme.primaryForeground,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        'Create story',
                        style: theme.textTheme.small.copyWith(
                          color: scheme.foreground,
                          fontWeight: FontWeight.w700,
                        ),
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
  }
}

/// Opens the stories full screen at [index].
Future<void> openStories(BuildContext context, int index) {
  return Navigator.of(context).push(
    UnaPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => StoryViewer(initial: index),
    ),
  );
}

/// The stories one after another: a progress bar per story across the top,
/// a tap on either half to step, and a reply field at the bottom.
class StoryViewer extends StatefulWidget {
  const StoryViewer({this.initial = 0, super.key});

  final int initial;

  /// How long a story shows.
  static const storyDuration = Duration(seconds: 5);

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late int _index = widget.initial;
  late final _progress = AnimationController(
    vsync: this,
    duration: StoryViewer.storyDuration,
  )..addStatusListener(_onStatus);
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _progress.forward();
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _step(1);
  }

  void _step(int delta) {
    final next = _index + delta;
    if (next < 0) {
      _progress.forward(from: 0);
      return;
    }
    if (next >= Stories.all.length) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() {
      _index = next;
      _liked = false;
    });
    _progress.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final story = Stories.all[_index];
    const white = Color(0xFFFFFFFF);
    final padding = MediaQuery.paddingOf(context);

    final viewer = ClipRRect(
      borderRadius: theme.isPhone ? BorderRadius.zero : theme.radii.xl,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ContentSwitch(
            value: _index,
            child: Image.asset(
              story.photo,
              key: ValueKey(_index),
              fit: BoxFit.cover,
              semanticLabel: '${story.person.name}\'s story',
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x88000000),
                  Color(0x00000000),
                  Color(0x00000000),
                  Color(0x99000000),
                ],
                stops: [0, .22, .7, 1],
              ),
            ),
          ),
          // Tap the start half to go back, the end half to go on; hold to
          // pause.
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _step(-1),
                  onLongPressStart: (_) => _progress.stop(),
                  onLongPressEnd: (_) => _progress.forward(),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _step(1),
                  onLongPressStart: (_) => _progress.stop(),
                  onLongPressEnd: (_) => _progress.forward(),
                ),
              ),
            ],
          ),
          PositionedDirectional(
            start: 12,
            end: 12,
            top: (theme.isPhone ? padding.top : 0) + 12,
            child: Column(
              children: [
                Row(
                  spacing: 4,
                  children: [
                    for (var i = 0; i < Stories.all.length; i++)
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: SizedBox(
                            height: 3,
                            child: AnimatedBuilder(
                              animation: _progress,
                              builder: (context, _) => LinearProgressBar(
                                value: i < _index
                                    ? 1
                                    : i == _index
                                    ? _progress.value
                                    : 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const Gap.sm(),
                Row(
                  children: [
                    PersonAvatar(story.person, size: 36),
                    const Gap.sm(),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: story.person.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: '  ${story.age}',
                              style: TextStyle(
                                color: white.withValues(alpha: .75),
                              ),
                            ),
                          ],
                        ),
                        style: theme.textTheme.small.copyWith(color: white),
                      ),
                    ),
                    IconButton.ghost(
                      icon: const PhosphorIcon(
                        PhosphorIconsBold.x,
                        color: white,
                      ),
                      semanticLabel: 'Close',
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PositionedDirectional(
            start: 12,
            end: 12,
            bottom: (theme.isPhone ? padding.bottom : 0) + 12,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    placeholder: Text('Reply to ${story.person.firstName}…'),
                    onTap: _progress.stop,
                    onSubmitted: (text) {
                      if (text.trim().isEmpty) return;
                      showSocialToast(
                        context,
                        'Reply sent to ${story.person.firstName}',
                        variant: ToastVariant.success,
                      );
                      _progress.forward();
                    },
                    style: theme.textTheme.small.copyWith(color: white),
                    placeholderStyle: theme.textTheme.small.copyWith(
                      color: white.withValues(alpha: .7),
                    ),
                    decoration: UnaDecoration(
                      color: white.withValues(alpha: .12),
                      border: UnaBorder.all(
                        color: white.withValues(alpha: .35),
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                ),
                const Gap.sm(),
                IconButton.ghost(
                  icon: PopIn(
                    visible: true,
                    key: ValueKey(_liked),
                    child: PhosphorIcon(
                      _liked
                          ? PhosphorIconsFill.heart
                          : PhosphorIconsRegular.heart,
                      color: _liked ? Reaction.love.color : white,
                    ),
                  ),
                  semanticLabel: 'Love this story',
                  onPressed: () => setState(() => _liked = !_liked),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return DismissShortcut(
      isActive: () => true,
      onDismiss: () => Navigator.of(context).maybePop(),
      // Focused, so that Escape reaches the shortcut.
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: const Color(0xFF0B0B10),
          child: theme.isPhone
              ? viewer
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: AspectRatio(aspectRatio: 9 / 16, child: viewer),
                  ),
                ),
        ),
      ),
    );
  }
}

/// A thin bar that fills from the start, white on translucent white.
class LinearProgressBar extends StatelessWidget {
  const LinearProgressBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x55FFFFFF),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: value.clamp(0, 1),
        child: const ColoredBox(color: Color(0xFFFFFFFF)),
      ),
    );
  }
}
