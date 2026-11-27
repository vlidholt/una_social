import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/pieces.dart';

/// Opens [photos] full screen on black, at [initial].
Future<void> openPhotos(
  BuildContext context,
  List<String> photos, {
  int initial = 0,
  Post? post,
}) {
  return Navigator.of(context).push(
    UnaPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) =>
          PhotoViewer(photos: photos, initial: initial, post: post),
    ),
  );
}

/// The pictures of a post, one at a time, swiped or stepped through, with
/// who posted them and the post's reactions underneath.
class PhotoViewer extends StatefulWidget {
  const PhotoViewer({
    required this.photos,
    this.initial = 0,
    this.post,
    super.key,
  });

  final List<String> photos;
  final int initial;
  final Post? post;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  late int _page = widget.initial;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The photo opened was just a thumbnail, so it is shown as it is; the
    // others are loaded now, before they are swiped to.
    precachePhotos(context, widget.photos);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    const white = Color(0xFFFFFFFF);
    final onDark = theme.textTheme.small.copyWith(color: white);
    final padding = MediaQuery.paddingOf(context);

    return DismissShortcut(
      isActive: () => true,
      onDismiss: () => Navigator.of(context).maybePop(),
      // Focused, so that Escape reaches the shortcut.
      child: Focus(
        autofocus: true,
        child: ColoredBox(
          color: const Color(0xFF050507),
          child: Stack(
            children: [
              Positioned.fill(
                child: Carousel(
                  initialPage: widget.initial,
                  onPageChanged: (page) => setState(() => _page = page),
                  showArrows: widget.photos.length > 1,
                  showIndicator: false,
                  semanticLabel: 'Photos',
                  children: [
                    for (final photo in widget.photos)
                      Image.asset(photo, fit: BoxFit.contain),
                  ],
                ),
              ),
              PositionedDirectional(
                top: padding.top + 12,
                start: 12,
                end: 12,
                child: Row(
                  children: [
                    Glass(
                      level: GlassLevel.strong,
                      borderRadius: theme.radii.full,
                      child: IconButton.ghost(
                        icon: const PhosphorIcon(
                          PhosphorIconsBold.x,
                          color: white,
                        ),
                        semanticLabel: 'Close',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                    const Spacer(),
                    if (widget.photos.length > 1)
                      Glass(
                        level: GlassLevel.strong,
                        borderRadius: theme.radii.full,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          '${_page + 1} / ${widget.photos.length}',
                          style: onDark.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
              if (post != null)
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC000000)],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        48,
                        20,
                        padding.bottom + 20,
                      ),
                      child: ListenableBuilder(
                        listenable: context.social,
                        builder: (context, _) => Row(
                          children: [
                            PersonAvatar(post.author, size: theme.avatarSm),
                            const Gap.sm(),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    post.author.name,
                                    style: onDark.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    post.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: onDark.copyWith(
                                      color: white.withValues(alpha: .8),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap.sm(),
                            _GlassReact(post),
                          ],
                        ),
                      ),
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

/// A heart on glass: loves the post from the viewer.
class _GlassReact extends StatelessWidget {
  const _GlassReact(this.post);

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mine = context.social.reactionOf(post);
    final loved = mine == Reaction.love;
    return Glass(
      level: GlassLevel.strong,
      borderRadius: theme.radii.full,
      child: IconButton.ghost(
        icon: PopIn(
          visible: true,
          key: ValueKey(loved),
          child: PhosphorIcon(
            loved ? PhosphorIconsFill.heart : PhosphorIconsRegular.heart,
            color: loved ? Reaction.love.color : const Color(0xFFFFFFFF),
          ),
        ),
        semanticLabel: loved ? 'Take back love' : 'Love',
        onPressed: () => context.social.react(post, Reaction.love),
      ),
    );
  }
}
