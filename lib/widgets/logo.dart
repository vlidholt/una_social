import 'package:flutter/widgets.dart';
import 'package:una/una.dart';

/// The Una Social mark — a speech bubble on a tile in the brand's indigo
/// to pink gradient, with a "u" cut into it — and the wordmark beside it.
///
/// The same painter draws the web app's icons (see
/// `test/app_icons_test.dart`).
class SocialLogo extends StatelessWidget {
  const SocialLogo({this.onPressed, this.showWordmark = true, super.key});

  final VoidCallback? onPressed;
  final bool showWordmark;

  // A brand asset: off the theme's scales on purpose.
  static const _gap = 10.0;

  static double _tile(ThemeData theme) =>
      theme.formFactor == FormFactor.mobile ? 32 : 34;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tile = _tile(theme);
    final style = theme.textTheme.large.copyWith(
      fontSize: 20,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -.03 * 20,
      color: scheme.foreground,
    );
    final logo = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: tile,
          child: const CustomPaint(painter: SocialMarkPainter()),
        ),
        if (showWordmark) ...[
          const SizedBox(width: _gap),
          ConstrainedBox(
            // The wordmark's own width in the brand face, with room to
            // spare: a wider fallback face clips rather than pushing the
            // bar's actions off the edge.
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'una'),
                  TextSpan(
                    text: 'social',
                    style: style.copyWith(
                      color: scheme.tint,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.clip,
              style: style,
            ),
          ),
        ],
      ],
    );
    if (onPressed == null) {
      return Semantics(
        label: 'Una Social',
        child: ExcludeSemantics(child: logo),
      );
    }
    return Pressable(
      onPressed: onPressed,
      semanticLabel: 'Una Social home',
      builder: (context, states) => FocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: BorderRadius.circular(tile * .3),
        child: ExcludeSemantics(child: logo),
      ),
    );
  }
}

/// Paints the mark into its whole box. [radius] is the tile's corner as a
/// share of its side: 0 for a square that a platform masks itself.
class SocialMarkPainter extends CustomPainter {
  const SocialMarkPainter({this.radius = .3, this.inset = 0});

  final double radius;

  /// How far in from the edges the bubble sits, as a share of the side, on
  /// top of its own margin: maskable icons keep their art in the middle.
  final double inset;

  static const indigo = Color(0xFF5046E5);
  static const violet = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final box = Offset.zero & Size.square(side);
    final tile = RSuperellipse.fromRectAndRadius(
      box,
      Radius.circular(side * radius),
    );
    // The gradient fills the tile through a clip, not `drawRSuperellipse`:
    // on the web (CanvasKit and skwasm) that draws a path centred on the
    // origin under a translation to the tile's centre, and the shader moves
    // with it, so the tile showed only the indigo half of the gradient and
    // never reached the pink the icons have. A clip is geometry only.
    canvas
      ..save()
      ..clipRSuperellipse(tile)
      ..drawRect(
        box,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [indigo, violet, pink],
            stops: [0, .55, 1],
          ).createShader(box),
      )
      // A soft sheen across the top, as glass catches it.
      ..drawRect(
        Rect.fromLTWH(0, 0, side, side * .5),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFFFFFFF).withValues(alpha: .16),
              const Color(0xFFFFFFFF).withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, side, side * .5)),
      )
      ..restore();

    // The bubble on a 24-unit grid, scaled into the tile.
    final art = side * (1 - inset * 2);
    final unit = art / 24;
    canvas
      ..save()
      ..translate(side * inset, side * inset)
      ..scale(unit);
    final bubble = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(4, 4.6, 16, 12.8),
          const Radius.circular(5.6),
        ),
      )
      // The tail, low on the left, wound clockwise like the rounded
      // rectangle so the two fill as one shape: wound the other way, the
      // nonzero rule cancelled them where they overlap and left a gap.
      // (Not `Path.combine`: on the web it returns its first operand.)
      ..moveTo(12.4, 16.8)
      ..quadraticBezierTo(9.8, 20.6, 4.8, 20.4)
      ..quadraticBezierTo(7.6, 19.2, 7.2, 15.6)
      ..close();
    canvas.drawPath(
      bubble,
      Paint()..color = const Color(0xFFFFFFFF),
    );
    // The "u", in the gradient's middle colour, cut into the bubble.
    final u = Path()
      ..moveTo(9, 8.4)
      ..lineTo(9, 11.2)
      ..arcToPoint(
        const Offset(15, 11.2),
        radius: const Radius.circular(3),
        clockwise: false,
      )
      ..lineTo(15, 8.4);
    canvas.drawPath(
      u,
      Paint()
        ..color = violet
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(SocialMarkPainter oldDelegate) =>
      radius != oldDelegate.radius || inset != oldDelegate.inset;
}
