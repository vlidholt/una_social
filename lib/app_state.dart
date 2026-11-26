import 'package:disco/disco.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:una/una.dart';

/// The app-wide settings: light or dark, Liquid Glass and the text size.
///
/// Provided above `UnaApp` (see `App` in `main.dart`), so every route —
/// the full-screen pages a screen pushes too — can read them. The Settings
/// page writes them, and so do the shell's quick switches.

final themeModeProvider = Provider((_) => Signal(ThemeMode.light));

/// Whether the app draws with Liquid Glass: `auto` on iOS and macOS, as
/// the package decides, or forced on or off — off to see on an iPhone what
/// every other platform gets.
final liquidGlassProvider = Provider((_) => Signal(LiquidGlassMode.auto));

/// The text scale the whole app is shown at, in place of the platform's.
///
/// Applied through `MediaQuery` in `App`, not through the theme, so a drag
/// of the Settings slider builds no theme.
final textScaleProvider = Provider((_) => Signal(1.0));

/// Every provider above, for the `ProviderScope` at the root of the app
/// (and of a test that pumps part of it).
final appProviders = <Provider<Object>>[
  themeModeProvider,
  liquidGlassProvider,
  textScaleProvider,
];

/// Flips between light and dark.
void toggleThemeMode(BuildContext context) {
  themeModeProvider
      .of(context)
      .updateValue(
        (mode) => mode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light,
      );
}
