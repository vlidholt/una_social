import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/pieces.dart';

/// "What's on your mind?": your portrait and a pill that opens the
/// composer, with Live, Photo and Feeling under it on a desktop.
class ComposerCard extends StatelessWidget {
  const ComposerCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phone = theme.isPhone;

    final pill = Pressable(
      onPressed: () => showComposer(context),
      semanticLabel: 'Create a post',
      builder: (context, states) => AnimatedFill(
        color: states.contains(WidgetState.hovered)
            ? Color.alphaBlend(
                scheme.foreground.withValues(alpha: .04),
                scheme.muted,
              )
            : scheme.muted,
        borderRadius: theme.radii.full,
        child: Container(
          height: 40,
          alignment: AlignmentDirectional.centerStart,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'What\'s on your mind, ${People.me.firstName}?',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.p.copyWith(color: scheme.mutedForeground),
          ),
        ),
      ),
    );

    final top = Row(
      children: [
        PersonAvatar(People.me),
        const Gap.sm(),
        Expanded(child: pill),
        if (phone) ...[
          const Gap.xs(),
          IconButton.ghost(
            icon: const PhosphorIcon(
              PhosphorIconsFill.images,
              color: Color(0xFF22C55E),
            ),
            semanticLabel: 'Add a photo',
            onPressed: () => showComposer(context, startWithPhoto: true),
          ),
        ],
      ],
    );

    if (phone) {
      return Card(
        style: CardTheme(padding: EdgeInsets.all(theme.gap(GapSize.md))),
        child: top,
      );
    }

    Widget action(
      IconData icon,
      Color color,
      String label,
      VoidCallback onPressed,
    ) => Expanded(
      child: Button.ghost(
        expands: true,
        onPressed: onPressed,
        style: ButtonTheme(foregroundColor: scheme.mutedForeground),
        leading: PhosphorIcon(icon, color: color),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final short = constraints.maxWidth < 460;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              top,
              const Gap.md(),
              const Divider(margin: EdgeInsets.zero),
              const Gap.sm(),
              Row(
                children: [
                  action(
                    PhosphorIconsFill.videoCamera,
                    const Color(0xFFF43F5E),
                    short ? 'Live' : 'Live video',
                    () => showSocialToast(
                      context,
                      'Going live is coming soon',
                      description: 'We will let you know when it is ready.',
                    ),
                  ),
                  action(
                    PhosphorIconsFill.images,
                    const Color(0xFF22C55E),
                    short ? 'Photo' : 'Photo/video',
                    () => showComposer(context, startWithPhoto: true),
                  ),
                  action(
                    PhosphorIconsFill.smiley,
                    const Color(0xFFF59E0B),
                    'Feeling',
                    () => showComposer(context, startWithFeeling: true),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Opens the composer: a dialog on a desktop, a sheet on a phone.
Future<void> showComposer(
  BuildContext context, {
  bool startWithPhoto = false,
  bool startWithFeeling = false,
}) {
  final composer = Composer(
    startWithPhoto: startWithPhoto,
    startWithFeeling: startWithFeeling,
  );
  if (Theme.of(context).isPhone) {
    return showSheet<void>(
      context: context,
      builder: (context) => Sheet(
        title: const Text('Create post'),
        detents: const [SheetDetent.fraction(.92)],
        child: composer,
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      title: const Text('Create post'),
      style: const DialogTheme(
        constraints: BoxConstraints(maxWidth: 540),
      ),
      child: composer,
    ),
  );
}

/// The post being written: text, up to four photos and a feeling.
class Composer extends StatefulWidget {
  const Composer({
    this.startWithPhoto = false,
    this.startWithFeeling = false,
    super.key,
  });

  final bool startWithPhoto;
  final bool startWithFeeling;

  /// The pictures the composer offers in place of a camera roll.
  static const library = [
    'assets/images/post_lisbon_1.jpg',
    'assets/images/story_coast.jpg',
    'assets/images/post_breakfast.jpg',
    'assets/images/story_meadow.jpg',
    'assets/images/post_hike.jpg',
    'assets/images/post_puppy.jpg',
  ];

  static const feelings = [
    ('happy', '😊'),
    ('grateful', '🙏'),
    ('excited', '🤩'),
    ('loved', '🥰'),
    ('relaxed', '😌'),
    ('proud', '💪'),
  ];

  @override
  State<Composer> createState() => _ComposerState();
}

class _ComposerState extends State<Composer> {
  final _text = TextEditingController();
  final _photos = <String>[];
  late bool _showLibrary = widget.startWithPhoto;
  late bool _showFeelings = widget.startWithFeeling;
  String? _feeling;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _canPost => _text.text.trim().isNotEmpty || _photos.isNotEmpty;

  Future<void> _post() async {
    setState(() => _posting = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    context.social.publish(
      _text.text.trim(),
      photos: [..._photos],
      feeling: _feeling == null ? null : 'feeling $_feeling',
    );
    Navigator.of(context).pop();
    showSocialToast(
      context,
      'Your post is live',
      variant: ToastVariant.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            PersonAvatar(People.me),
            const Gap.sm(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: People.me.name),
                        if (_feeling != null)
                          TextSpan(
                            text: ' is feeling $_feeling',
                            style: const TextStyle(fontWeight: FontWeight.w400),
                          ),
                      ],
                    ),
                    style: theme.textTheme.small.copyWith(
                      color: scheme.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Badge.secondary(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        PhosphorIcon(
                          PhosphorIconsFill.usersThree,
                          size: 12,
                          color: scheme.secondaryForeground,
                        ),
                        const Text('Friends'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Gap.md(),
        Textarea(
          controller: _text,
          autofocus: !theme.isPhone,
          placeholder: Text('What\'s on your mind, ${People.me.firstName}?'),
        ),
        if (_photos.isNotEmpty) ...[
          const Gap.md(),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (context, index) => const Gap.sm(),
              itemBuilder: (context, index) => Stack(
                children: [
                  SizedBox(
                    width: 92,
                    child: Photo(
                      _photos[index],
                      height: 92,
                      borderRadius: theme.radii.md,
                    ),
                  ),
                  PositionedDirectional(
                    top: 4,
                    end: 4,
                    child: Glass(
                      level: GlassLevel.strong,
                      borderRadius: theme.radii.full,
                      child: IconButton.ghost(
                        size: ButtonSize.sm,
                        icon: const PhosphorIcon(PhosphorIconsBold.x),
                        semanticLabel: 'Remove photo',
                        onPressed: () =>
                            setState(() => _photos.removeAt(index)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        Reveal(
          expanded: _showLibrary,
          child: Padding(
            padding: EdgeInsets.only(top: theme.gap(GapSize.md)),
            child: _PhotoLibrary(
              selected: _photos,
              onToggled: (photo) => setState(() {
                if (!_photos.remove(photo) && _photos.length < 4) {
                  _photos.add(photo);
                }
              }),
            ),
          ),
        ),
        Reveal(
          expanded: _showFeelings,
          child: Padding(
            padding: EdgeInsets.only(top: theme.gap(GapSize.md)),
            child: Wrap(
              spacing: theme.gap(GapSize.xs),
              runSpacing: theme.gap(GapSize.xs),
              children: [
                for (final (feeling, emoji) in Composer.feelings)
                  Chip(
                    selected: _feeling == feeling,
                    onSelected: (selected) =>
                        setState(() => _feeling = selected ? feeling : null),
                    leading: Text(emoji),
                    label: Text(feeling),
                  ),
              ],
            ),
          ),
        ),
        const Gap.md(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: theme.radii.lg,
            border: Border.all(color: scheme.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Add to your post',
                  style: theme.textTheme.small.copyWith(
                    color: scheme.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Toggle(
                value: _showLibrary,
                onChanged: (value) => setState(() => _showLibrary = value),
                semanticLabel: 'Photo',
                child: const PhosphorIcon(
                  PhosphorIconsFill.images,
                  color: Color(0xFF22C55E),
                ),
              ),
              Toggle(
                value: _showFeelings,
                onChanged: (value) => setState(() => _showFeelings = value),
                semanticLabel: 'Feeling',
                child: const PhosphorIcon(
                  PhosphorIconsFill.smiley,
                  color: Color(0xFFF59E0B),
                ),
              ),
              Toggle(
                value: false,
                onChanged: (_) => showSocialToast(
                  context,
                  'Tag friends from the post once it is live',
                ),
                semanticLabel: 'Tag people',
                child: const PhosphorIcon(
                  PhosphorIconsFill.userPlus,
                  color: Color(0xFF5046E5),
                ),
              ),
              Toggle(
                value: false,
                onChanged: (_) => setState(
                  () => _text.text =
                      '${_text.text}${_text.text.isEmpty ? '' : ' '}📍 Lisbon',
                ),
                semanticLabel: 'Check in',
                child: const PhosphorIcon(
                  PhosphorIconsFill.mapPin,
                  color: Color(0xFFF43F5E),
                ),
              ),
            ],
          ),
        ),
        const Gap.md(),
        Button(
          expands: true,
          loading: _posting,
          onPressed: _canPost && !_posting ? _post : null,
          child: const Text('Post'),
        ),
      ],
    );
  }
}

class _PhotoLibrary extends StatelessWidget {
  const _PhotoLibrary({required this.selected, required this.onToggled});

  final List<String> selected;
  final ValueChanged<String> onToggled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      children: [
        for (final photo in Composer.library)
          Pressable(
            onPressed: () => onToggled(photo),
            selected: selected.contains(photo),
            semanticLabel: 'Photo',
            builder: (context, states) {
              final index = selected.indexOf(photo);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Photo(photo, borderRadius: theme.radii.md),
                  AnimatedOpacity(
                    opacity: index < 0 ? 0 : 1,
                    duration: Motion.of(context).fast,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: theme.radii.md,
                        border: Border.all(color: scheme.primary, width: 3),
                        color: scheme.primary.withValues(alpha: .18),
                      ),
                    ),
                  ),
                  if (index >= 0)
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: PopIn(
                        visible: true,
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: scheme.primary,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.caption.copyWith(
                              color: scheme.primaryForeground,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
