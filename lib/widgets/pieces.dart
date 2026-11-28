import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';

/// Shorthands for the theme's scales, used across the screens.
extension SocialMetrics on ThemeData {
  double gap(GapSize size) => layoutTheme.gap(size);

  bool get isPhone => formFactor == FormFactor.mobile;

  /// The theme's avatar size: 40 on a desktop.
  double get avatarMd => avatarTheme.size?.shortestSide ?? 40;

  double get avatarSm => (avatarMd * .8).roundToDouble();

  double get avatarXs => (avatarMd * .6).roundToDouble();

  double get avatarLg => (avatarMd * 1.4).roundToDouble();

  /// The page margin on this form factor.
  double get margin =>
      (layoutTheme.pagePadding ?? const EdgeInsets.all(16)).horizontal / 2;

  /// A pill-shaped text field on the muted fill, with no outline: the
  /// comment field and the message composer.
  ///
  /// The focus ring is the theme's own decoration (`ThemeData.decoration`),
  /// baked on the control radius, so a field that only rounds its `border`
  /// keeps a rounded-rectangle ring around a pill. [buttonDecoration] sets
  /// the ring on the same radius as the border.
  UnaDecoration get pillFieldDecoration =>
      buttonDecoration(radius: radii.full).copyWith(
        color: colorScheme.muted,
        border: UnaBorder.all(
          color: const Color(0x00000000),
          borderRadius: radii.full,
        ),
      );
}

/// A person's portrait, with an optional green dot when they are online and
/// an optional ring when they have a story.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar(
    this.person, {
    this.size,
    this.showOnline = false,
    this.storyRing = false,
    super.key,
  });

  final Person person;
  final double? size;
  final bool showOnline;

  /// A ring in the brand's gradient: they have a story you have not seen.
  final bool storyRing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final side = size ?? theme.avatarMd;
    Widget avatar = Avatar(
      person.photo,
      size: Size.square(side),
      fallback: Text(person.initials),
    );
    if (storyRing) {
      final ring = (side / 18).clamp(2.0, 3.0);
      avatar = Container(
        padding: EdgeInsets.all(ring),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [scheme.primary, const Color(0xFFEC4899)],
          ),
        ),
        child: Container(
          padding: EdgeInsets.all(ring * .8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.card,
          ),
          child: Avatar(
            person.photo,
            size: Size.square(side - ring * 3.6),
            fallback: Text(person.initials),
          ),
        ),
      );
    }
    if (!showOnline || !person.online) {
      return ExcludeSemantics(child: avatar);
    }
    final dot = (side * .28).clamp(9.0, 16.0);
    return ExcludeSemantics(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          PositionedDirectional(
            end: -1,
            bottom: -1,
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF22C55E),
                border: Border.all(color: scheme.card, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reaction's icon on a disc of its colour, as the reaction counts and
/// the picker show it.
class ReactionDisc extends StatelessWidget {
  const ReactionDisc(this.reaction, {this.size = 18, this.ring, super.key});

  final Reaction reaction;
  final double size;

  /// A ring in the surface's colour, where discs overlap.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(reaction.color, const Color(0xFFFFFFFF), .18)!,
            reaction.color,
          ],
        ),
        border: ring == null ? null : Border.all(color: ring!, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Icon(
        reaction.icon,
        size: size * .58,
        color: const Color(0xFFFFFFFF),
      ),
    );
  }
}

/// Starts loading the photographs [assets] into the image cache, so a
/// [RevealImage] of one is simply there when it is built.
void precachePhotos(BuildContext context, Iterable<String> assets) {
  for (final asset in assets) {
    unawaited(RevealImage.precache(context, AssetImage(asset)));
  }
}

/// A photograph clipped to the theme's corners.
class Photo extends StatelessWidget {
  const Photo(
    this.asset, {
    this.aspectRatio,
    this.borderRadius,
    this.semanticLabel,
    this.height,
    super.key,
  });

  final String asset;
  final double? aspectRatio;
  final BorderRadius? borderRadius;
  final String? semanticLabel;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget image = RevealImage.asset(
      asset,
      fit: BoxFit.cover,
      semanticLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
      errorBuilder: (context, error, stackTrace) =>
          ColoredBox(color: theme.colorScheme.muted),
    );
    if (height != null) {
      image = SizedBox(height: height, width: double.infinity, child: image);
    } else if (aspectRatio != null) {
      image = AspectRatio(aspectRatio: aspectRatio!, child: image);
    }
    return ClipRRect(
      borderRadius: borderRadius ?? theme.radii.lg,
      child: image,
    );
  }
}

/// A section's heading on a page: a title, and an action at the end.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title, {this.action, this.subtitle, super.key});

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.h4.copyWith(
                    color: theme.colorScheme.foreground,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle!, style: theme.textTheme.muted),
              ],
            ),
          ),
        ),
        ?action,
      ],
    );
  }
}

/// The page's own title on a desktop page, under the shell's bar.
class PageTitle extends StatelessWidget {
  const PageTitle(
    this.title, {
    this.subtitle,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style:
                      (theme.isPhone ? theme.textTheme.h3 : theme.textTheme.h2)
                          .copyWith(color: theme.colorScheme.foreground),
                ),
                if (subtitle != null) ...[
                  const Gap.xs(),
                  Text(subtitle!, style: theme.textTheme.muted),
                ],
              ],
            ),
          ),
        ),
        for (final action in actions) ...[const Gap.sm(), action],
      ],
    );
  }
}

/// A month and a day on a small tile, as an event shows its date.
class DateTile extends StatelessWidget {
  const DateTile({
    required this.month,
    required this.day,
    this.size = 52,
    super.key,
  });

  final String month;
  final int day;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.card,
        borderRadius: theme.radii.md,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withValues(alpha: .12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month,
            style: theme.textTheme.caption.copyWith(
              color: const Color(0xFFF43F5E),
              fontWeight: FontWeight.w700,
              height: 1.1,
            ),
          ),
          Text(
            '$day',
            style: theme.textTheme.large.copyWith(
              color: scheme.foreground,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a toast with the app's defaults.
void showSocialToast(
  BuildContext context,
  String title, {
  String? description,
  ToastVariant variant = ToastVariant.neutral,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final toaster = Toaster.of(context);
  late final Object id;
  id = toaster.show(
    Toast(
      variant: variant,
      title: Text(title),
      description: description == null ? null : Text(description),
      action: actionLabel == null
          ? null
          : Button.outline(
              size: ButtonSize.sm,
              onPressed: () {
                toaster.dismiss(id);
                onAction?.call();
              },
              child: Text(actionLabel),
            ),
    ),
  );
}

/// Formats a count the way the feed does: 940, 1.2K, 18K.
String compactCount(int value) {
  if (value < 1000) return '$value';
  if (value < 10000) {
    final k = value / 1000;
    final text = k.toStringAsFixed(1);
    return '${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}K';
  }
  return '${(value / 1000).round()}K';
}

/// Opens and closes [child] on the theme's smooth spring.
class Reveal extends StatelessWidget {
  const Reveal({required this.expanded, required this.child, super.key});

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SpringBuilder(
      value: expanded ? 1.0 : 0.0,
      spring: Motion.of(context).smooth,
      builder: (context, t, child) =>
          ExpandReveal(factor: t.clamp(0.0, 1.0), child: child!),
      child: child,
    );
  }
}

/// A button's label that gives way with an ellipsis when the button is
/// narrower than its text: a [Button] lays its child out at its natural
/// width.
class ButtonLabel extends StatelessWidget {
  const ButtonLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Flexible(
    child: Text(
      text,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    ),
  );
}
