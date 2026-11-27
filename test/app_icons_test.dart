import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una_social/widgets/logo.dart';

/// The web app's icons are the in-app mark, painted at each size.
///
/// `UPDATE_APP_ICONS=1 flutter test test/app_icons_test.dart` writes them
/// to `web/`; otherwise the test only checks that the mark paints.
void main() {
  Future<List<int>> render(int size, SocialMarkPainter painter) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter.paint(canvas, Size.square(size.toDouble()));
    final image = await recorder.endRecording().toImage(size, size);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes!.buffer.asUint8List();
  }

  testWidgets('the mark paints, and writes the icons when asked', (
    tester,
  ) async {
    final update = Platform.environment['UPDATE_APP_ICONS'] == '1';
    // Rounded for a favicon and the plain icons; square, with the art in
    // the safe middle, for the maskable ones a platform crops itself; and
    // square to the edges for the Apple touch icon, which iOS rounds
    // itself (it fills transparent corners with black).
    final icons = {
      'web/favicon.png': (32, const SocialMarkPainter()),
      'web/icons/Icon-192.png': (192, const SocialMarkPainter()),
      'web/icons/Icon-512.png': (512, const SocialMarkPainter()),
      'web/icons/apple-touch-icon.png': (
        180,
        const SocialMarkPainter(radius: 0),
      ),
      'web/icons/Icon-maskable-192.png': (
        192,
        const SocialMarkPainter(radius: 0, inset: .1),
      ),
      'web/icons/Icon-maskable-512.png': (
        512,
        const SocialMarkPainter(radius: 0, inset: .1),
      ),
    };
    await tester.runAsync(() async {
      for (final MapEntry(key: path, value: (size, painter)) in icons.entries) {
        final png = await render(size, painter);
        expect(png, isNotEmpty);
        if (update) File(path).writeAsBytesSync(png);
      }
    });
  });
}
