import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/photo_viewer.dart';
import 'package:una_social/widgets/pieces.dart';

/// A post in a feed: who, what, the pictures, the reactions, and the
/// conversation under it.
///
/// One card on every form factor. On a phone its pictures run to the
/// card's edges and the action row drops its labels' weight; on a desktop
/// the reaction picker opens on hover as well as on a long press.
class PostCard extends StatefulWidget {
  const PostCard(this.post, {this.showComments = true, super.key});

  final Post post;

  /// Whether the conversation is shown under the post.
  final bool showComments;

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final _commentFocus = FocusNode(debugLabel: 'Write a comment');
  bool _allComments = false;

  @override
  void dispose() {
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final inset = theme.gap(theme.isPhone ? GapSize.md : GapSize.lg);
    final pad = EdgeInsets.symmetric(horizontal: inset);

    return ListenableBuilder(
      listenable: context.social,
      builder: (context, _) {
        final session = context.social;
        final comments = session.commentsOf(post);
        final shown = _allComments || comments.length <= 2
            ? comments
            : comments.sublist(comments.length - 2);
        return Card(
          style: const CardTheme(padding: EdgeInsets.zero),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: inset),
              Padding(padding: pad, child: _PostHeader(post)),
              if (post.backdrop == null && post.text.isNotEmpty) ...[
                Gap.raw(theme.gap(GapSize.sm) + 2),
                Padding(
                  padding: pad,
                  child: Text(
                    post.text,
                    style: theme.textTheme.p.copyWith(
                      color: theme.colorScheme.foreground,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
              if (post.backdrop != null) ...[
                const Gap.md(),
                _Backdrop(post),
              ],
              if (post.photos.isNotEmpty) ...[
                const Gap.md(),
                _PhotoGrid(post),
              ],
              if (post.event != null) ...[
                const Gap.md(),
                Padding(padding: pad, child: SharedEventCard(post.event!)),
              ],
              Padding(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  theme.gap(GapSize.md),
                  inset,
                  theme.gap(GapSize.sm),
                ),
                child: _ReactionSummary(
                  post,
                  onComments: () => setState(() => _allComments = true),
                ),
              ),
              Padding(
                padding: pad,
                child: const Divider(margin: EdgeInsets.zero),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: inset - theme.gap(GapSize.sm),
                  vertical: theme.gap(GapSize.xs),
                ),
                child: _Actions(
                  post,
                  onComment: () {
                    setState(() => _allComments = true);
                    _commentFocus.requestFocus();
                  },
                ),
              ),
              if (widget.showComments) ...[
                Padding(
                  padding: pad,
                  child: const Divider(margin: EdgeInsets.zero),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    inset,
                    theme.gap(GapSize.md),
                    inset,
                    inset,
                  ),
                  child: UnaColumn(
                    gap: GapSize.md,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (comments.length > shown.length)
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Button.link(
                            onPressed: () =>
                                setState(() => _allComments = true),
                            child: Text(
                              'View ${comments.length - shown.length} more '
                              '${comments.length - shown.length == 1 ? 'comment' : 'comments'}',
                            ),
                          ),
                        ),
                      for (final comment in shown)
                        Entrance(
                          key: ObjectKey(comment),
                          child: CommentBubble(comment),
                        ),
                      _CommentField(post: post, focusNode: _commentFocus),
                    ],
                  ),
                ),
              ] else
                SizedBox(height: theme.gap(GapSize.xs)),
            ],
          ),
        );
      },
    );
  }
}

/// Portrait, name, where and when, and the post's menu.
class _PostHeader extends StatelessWidget {
  const _PostHeader(this.post);

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final author = post.author;
    final nameStyle = theme.textTheme.small.copyWith(
      color: scheme.foreground,
      fontWeight: FontWeight.w700,
    );
    final quiet = theme.textTheme.small.copyWith(
      color: scheme.foreground,
      fontWeight: FontWeight.w400,
    );

    final title = <InlineSpan>[
      TextSpan(text: author.name, style: nameStyle),
      if (post.feeling != null)
        TextSpan(text: ' is ${post.feeling}', style: quiet),
      if (post.place != null) ...[
        TextSpan(text: ' at ', style: quiet),
        TextSpan(text: post.place, style: nameStyle),
      ],
      if (post.group != null) ...[
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: PhosphorIcon(
              PhosphorIconsFill.caretRight,
              size: 10,
              color: scheme.mutedForeground,
            ),
          ),
        ),
        TextSpan(text: post.group!.name, style: nameStyle),
      ],
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Pressable(
          onPressed: () => openProfile(context, author),
          semanticLabel: author.name,
          builder: (context, states) => PersonAvatar(author),
        ),
        const Gap.sm(),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 1),
              Text.rich(TextSpan(children: title)),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(post.age, style: theme.textTheme.caption),
                  Text(' · ', style: theme.textTheme.caption),
                  PhosphorIcon(
                    post.group?.private == true
                        ? PhosphorIconsFill.lockSimple
                        : PhosphorIconsFill.globeHemisphereWest,
                    size: 12,
                    color: scheme.mutedForeground,
                  ),
                ],
              ),
            ],
          ),
        ),
        const Gap.xs(),
        PostMenu(post),
      ],
    );
  }
}

/// A short text post, large and white on a gradient.
class _Backdrop extends StatelessWidget {
  const _Backdrop(this.post);

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: theme.isPhone ? 1.25 : 1.6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: post.backdrop!.colors,
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(theme.gap(GapSize.xl)),
            child: Text(
              post.text,
              textAlign: TextAlign.center,
              style: theme.textTheme.h3.copyWith(
                color: const Color(0xFFFFFFFF),
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One, two or three pictures, edge to edge; a tap opens them full screen.
class _PhotoGrid extends StatelessWidget {
  const _PhotoGrid(this.post);

  final Post post;

  @override
  Widget build(BuildContext context) {
    final photos = post.photos;
    const gap = 3.0;

    Widget tile(int index) => Pressable(
      onPressed: () => openPhotos(context, photos, initial: index, post: post),
      semanticLabel: 'Photo ${index + 1} of ${photos.length}',
      builder: (context, states) => RevealImage.asset(
        photos[index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        excludeFromSemantics: true,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: Theme.of(context).colorScheme.muted,
        ),
      ),
    );

    final Widget grid = switch (photos.length) {
      1 => AspectRatio(aspectRatio: 4 / 3, child: tile(0)),
      2 => AspectRatio(
        aspectRatio: 2,
        child: Row(
          spacing: gap,
          children: [
            Expanded(child: tile(0)),
            Expanded(child: tile(1)),
          ],
        ),
      ),
      _ => AspectRatio(
        aspectRatio: 4 / 3,
        child: Row(
          spacing: gap,
          children: [
            Expanded(flex: 3, child: tile(0)),
            Expanded(
              flex: 2,
              child: Column(
                spacing: gap,
                children: [
                  Expanded(child: tile(1)),
                  Expanded(child: tile(2)),
                ],
              ),
            ),
          ],
        ),
      ),
    };
    return grid;
  }
}

/// An event shared in a post.
class SharedEventCard extends StatelessWidget {
  const SharedEventCard(this.event, {super.key});

  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: context.social,
      builder: (context, _) {
        final rsvp = context.social.rsvpOf(event);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: theme.radii.lg,
            border: Border.all(color: scheme.border),
          ),
          child: ClipRRect(
            borderRadius: theme.radii.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Stack(
                  children: [
                    Photo(
                      event.photo,
                      aspectRatio: 2.2,
                      borderRadius: BorderRadius.zero,
                    ),
                    PositionedDirectional(
                      start: 12,
                      top: 12,
                      child: DateTile(month: event.month, day: event.day),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.all(theme.gap(GapSize.md)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event.when.toUpperCase(),
                              style: theme.textTheme.caption.copyWith(
                                color: const Color(0xFFF43F5E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              event.title,
                              style: theme.textTheme.large.copyWith(
                                color: scheme.foreground,
                              ),
                            ),
                            Text(
                              '${event.where} · ${compactCount(event.interested)} interested',
                              style: theme.textTheme.muted,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Gap.sm(),
                      Button.secondary(
                        leading: PhosphorIcon(
                          rsvp == Rsvp.none
                              ? PhosphorIconsRegular.star
                              : PhosphorIconsFill.star,
                        ),
                        onPressed: () => context.social.setRsvp(
                          event,
                          rsvp == Rsvp.none ? Rsvp.interested : Rsvp.none,
                        ),
                        child: ButtonLabel(
                          rsvp == Rsvp.none ? 'Interested' : 'Saved',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The overlapping reaction discs and their total, and the comment and
/// share counts.
class _ReactionSummary extends StatelessWidget {
  const _ReactionSummary(this.post, {required this.onComments});

  final Post post;
  final VoidCallback onComments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.social;
    final reactions = session.reactionsOf(post);
    final total = session.reactionCount(post);
    final mine = session.reactionOf(post);
    final comments = session.commentsOf(post).length;
    final top = reactions.take(3).map((entry) => entry.key).toList();
    final muted = theme.textTheme.muted;

    final count = mine == null
        ? compactCount(total)
        : total == 1
        ? 'You'
        : 'You and ${compactCount(total - 1)} others';

    return Row(
      children: [
        if (top.isNotEmpty)
          SizedBox(
            width: 18.0 + (top.length - 1) * 14,
            height: 20,
            child: Stack(
              children: [
                for (final (index, reaction) in top.indexed.toList().reversed)
                  PositionedDirectional(
                    start: index * 14.0,
                    top: 1,
                    child: ReactionDisc(reaction, ring: theme.colorScheme.card),
                  ),
              ],
            ),
          ),
        const Gap.xs(),
        Expanded(
          child: ContentSwitch(
            value: count,
            direction: 0,
            child: Text(
              count,
              style: muted,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        if (comments > 0 || post.shares > 0)
          Flexible(
            child: Pressable(
              onPressed: onComments,
              semanticLabel: '$comments comments',
              builder: (context, states) => Text(
                [
                  if (comments > 0)
                    '$comments ${comments == 1 ? 'comment' : 'comments'}',
                  if (post.shares > 0)
                    '${post.shares} ${post.shares == 1 ? 'share' : 'shares'}',
                ].join(' · '),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: muted,
              ),
            ),
          ),
      ],
    );
  }
}

/// Like (with the reaction picker), Comment and Share.
class _Actions extends StatelessWidget {
  const _Actions(this.post, {required this.onComment});

  final Post post;
  final VoidCallback onComment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: LikeButton(post)),
        Expanded(
          child: _ActionButton(
            icon: PhosphorIconsRegular.chatCircle,
            label: 'Comment',
            onPressed: onComment,
          ),
        ),
        Expanded(
          child: _ActionButton(
            icon: PhosphorIconsRegular.shareFat,
            label: 'Share',
            onPressed: () => sharePost(context, post),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.onLongPress,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // Not `expands`: that stretches the label and leaves the icon at the
    // start. Given the row's share of the width, the button centres its
    // icon and label as one group, and the label still gives way.
    return Button.ghost(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: ButtonTheme(
        foregroundColor: color ?? scheme.mutedForeground,
        hoverForegroundColor: color ?? scheme.foreground,
        // Three to a row on a phone: a label keeps its room.
        padding: theme.isPhone
            ? const EdgeInsets.symmetric(horizontal: 6)
            : null,
      ),
      leading: PhosphorIcon(icon, color: color),
      child: Flexible(
        child: Text(
          label,
          style: TextStyle(color: color),
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// The Like button: a tap likes, and a long press — or resting the mouse
/// on it — opens the reactions.
class LikeButton extends StatefulWidget {
  const LikeButton(this.post, {super.key});

  final Post post;

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  final _controller = PopoverController();
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _hoverIn() {
    _timer?.cancel();
    if (_controller.isOpen) return;
    _timer = Timer(const Duration(milliseconds: 450), _controller.open);
  }

  void _hoverOut() {
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 300), _controller.close);
  }

  void _pick(Reaction reaction) {
    _timer?.cancel();
    _controller.close();
    context.social.react(widget.post, reaction);
    Haptics.selection(context);
  }

  @override
  Widget build(BuildContext context) {
    final session = context.social;
    final mine = session.reactionOf(widget.post);
    return Popover(
      controller: _controller,
      // Above the button, as reactions rise from it.
      anchor: const Anchor(
        childAlignment: AlignmentDirectional.topStart,
        overlayAlignment: AlignmentDirectional.bottomStart,
        offset: Offset(0, -6),
      ),
      padding: const EdgeInsets.all(6),
      builder: (context) => MouseRegion(
        onEnter: (_) => _timer?.cancel(),
        onExit: (_) => _hoverOut(),
        child: _ReactionPicker(selected: mine, onPicked: _pick),
      ),
      child: MouseRegion(
        onEnter: (event) {
          if (event.kind == PointerDeviceKind.mouse) _hoverIn();
        },
        onExit: (_) => _hoverOut(),
        child: _ActionButton(
          icon: mine == null || mine == Reaction.like
              ? (mine == null
                    ? PhosphorIconsRegular.thumbsUp
                    : PhosphorIconsFill.thumbsUp)
              : mine.icon,
          label: mine?.label ?? 'Like',
          color: mine?.color,
          onPressed: () {
            _timer?.cancel();
            _controller.close();
            session.toggleLike(widget.post);
          },
          onLongPress: _controller.open,
        ),
      ),
    );
  }
}

/// The row of reactions: each grows under the pointer and pops when
/// picked.
class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({required this.selected, required this.onPicked});

  final Reaction? selected;
  final ValueChanged<Reaction> onPicked;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final reaction in Reaction.values)
          Pressable(
            onPressed: () => onPicked(reaction),
            semanticLabel: reaction.label,
            pressScale: .85,
            builder: (context, states) {
              final hovered = states.contains(WidgetState.hovered);
              return Tooltip(
                builder: (context) => Text(reaction.label),
                child: SpringBuilder(
                  value: hovered ? 1.0 : 0.0,
                  spring: Motion.of(context).snappy,
                  builder: (context, t, child) => Transform.translate(
                    offset: Offset(0, -6 * t),
                    child: Transform.scale(scale: 1 + .28 * t, child: child),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: ReactionDisc(reaction, size: 36),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

/// A comment: portrait, a bubble with name and text, and Like · Reply.
class CommentBubble extends StatefulWidget {
  const CommentBubble(this.comment, {super.key});

  final Comment comment;

  @override
  State<CommentBubble> createState() => _CommentBubbleState();
}

class _CommentBubbleState extends State<CommentBubble> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final comment = widget.comment;
    final likes = comment.likes + (_liked ? 1 : 0);
    final link = theme.textTheme.caption.copyWith(fontWeight: FontWeight.w700);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PersonAvatar(comment.author, size: theme.avatarSm),
        const Gap.sm(),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 9),
                    decoration: BoxDecoration(
                      color: scheme.muted,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          comment.author.name,
                          style: theme.textTheme.small.copyWith(
                            color: scheme.foreground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          comment.text,
                          style: theme.textTheme.small.copyWith(
                            color: scheme.foreground,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (likes > 0)
                    PositionedDirectional(
                      end: -6,
                      bottom: -8,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(2, 2, 6, 2),
                        decoration: BoxDecoration(
                          color: scheme.card,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF000000)
                                  .withValues(alpha: .12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const ReactionDisc(Reaction.like, size: 16),
                            const SizedBox(width: 3),
                            Text('$likes', style: theme.textTheme.caption),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 14,
                  children: [
                    Text(comment.age, style: theme.textTheme.caption),
                    Pressable(
                      onPressed: () => setState(() => _liked = !_liked),
                      semanticLabel: _liked ? 'Unlike comment' : 'Like comment',
                      builder: (context, states) => Text(
                        'Like',
                        style: link.copyWith(
                          color: _liked ? Reaction.like.color : null,
                        ),
                      ),
                    ),
                    Text('Reply', style: link),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Write a comment…": your portrait and a rounded field that posts on
/// Enter or with its send button.
class _CommentField extends StatefulWidget {
  const _CommentField({required this.post, required this.focusNode});

  final Post post;
  final FocusNode focusNode;

  @override
  State<_CommentField> createState() => _CommentFieldState();
}

class _CommentFieldState extends State<_CommentField> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    context.social.comment(widget.post, text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final empty = _controller.text.trim().isEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        PersonAvatar(People.me, size: theme.avatarSm),
        const Gap.sm(),
        Expanded(
          child: TextField(
            controller: _controller,
            focusNode: widget.focusNode,
            placeholder: const Text('Write a comment…'),
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            decoration: theme.pillFieldDecoration,
            trailing: IconButton.ghost(
              size: ButtonSize.sm,
              icon: PhosphorIcon(
                PhosphorIconsFill.paperPlaneRight,
                color: empty ? scheme.mutedForeground : scheme.tint,
              ),
              semanticLabel: 'Post comment',
              onPressed: empty ? null : _send,
            ),
          ),
        ),
      ],
    );
  }
}

/// The post's "More" button: a menu under it on a desktop, an action sheet
/// on a phone.
class PostMenu extends StatelessWidget {
  const PostMenu(this.post, {super.key});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final session = context.social;
    final saved = session.isSaved(post);
    final actions = <(IconData, String, VoidCallback, bool)>[
      (
        saved
            ? PhosphorIconsFill.bookmarkSimple
            : PhosphorIconsRegular.bookmarkSimple,
        saved ? 'Remove from saved' : 'Save post',
        () {
          session.toggleSaved(post);
          showSocialToast(
            context,
            saved ? 'Removed from saved' : 'Saved',
            description: saved ? null : 'Find it under Saved in your menu.',
            variant: saved ? ToastVariant.neutral : ToastVariant.success,
          );
        },
        false,
      ),
      (
        PhosphorIconsRegular.link,
        'Copy link',
        () {
          Clipboard.setData(ClipboardData(text: 'una.social/p/${post.id}'));
          showSocialToast(context, 'Link copied');
        },
        false,
      ),
      if (post.author != People.me)
        (
          PhosphorIconsRegular.eyeSlash,
          'Hide post',
          () {
            session.hide(post);
            showSocialToast(
              context,
              'Post hidden',
              description: 'You will see fewer posts like this.',
              actionLabel: 'Undo',
              onAction: () => session.unhide(post),
            );
          },
          true,
        ),
    ];

    final theme = Theme.of(context);
    if (theme.isPhone) {
      return IconButton.ghost(
        size: ButtonSize.sm,
        icon: const PhosphorIcon(PhosphorIconsBold.dotsThree),
        semanticLabel: 'More options',
        onPressed: () async {
          final index = await showActionSheet<int>(
            context: context,
            actions: [
              for (final (index, (icon, label, _, destructive))
                  in actions.indexed)
                ActionSheetAction(
                  label: Text(label),
                  icon: PhosphorIcon(icon),
                  value: index,
                  destructive: destructive,
                ),
            ],
          );
          if (index != null) actions[index].$3();
        },
      );
    }
    return DropdownMenu(
      items: [
        for (final (icon, label, onPressed, destructive) in actions)
          MenuItem(
            leading: PhosphorIcon(icon),
            destructive: destructive,
            onPressed: onPressed,
            child: Text(label),
          ),
      ],
      builder: (context, controller, child) => IconButton.ghost(
        size: ButtonSize.sm,
        icon: const PhosphorIcon(PhosphorIconsBold.dotsThree),
        semanticLabel: 'More options',
        onPressed: controller.toggle,
      ),
    );
  }
}

/// Shares a post: to your feed, in a message, or as a link.
Future<void> sharePost(BuildContext context, Post post) async {
  final choice = await showActionSheet<String>(
    context: context,
    title: Text('Share ${post.author.firstName}\'s post'),
    actions: const [
      ActionSheetAction(
        label: Text('Share now'),
        icon: PhosphorIcon(PhosphorIconsRegular.shareFat),
        value: 'feed',
        isDefault: true,
      ),
      ActionSheetAction(
        label: Text('Send in a message'),
        icon: PhosphorIcon(PhosphorIconsRegular.messengerLogo),
        value: 'message',
      ),
      ActionSheetAction(
        label: Text('Copy link'),
        icon: PhosphorIcon(PhosphorIconsRegular.link),
        value: 'link',
      ),
    ],
  );
  if (!context.mounted || choice == null) return;
  switch (choice) {
    case 'feed':
      showSocialToast(
        context,
        'Shared to your feed',
        variant: ToastVariant.success,
      );
    case 'message':
      context.goTo(Destination.messages);
    case 'link':
      await Clipboard.setData(ClipboardData(text: 'una.social/p/${post.id}'));
      if (context.mounted) showSocialToast(context, 'Link copied');
  }
}
