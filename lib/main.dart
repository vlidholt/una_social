import 'package:disco/disco.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:una/una.dart';
import 'package:una_social/app_state.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/session.dart';
import 'package:una_social/shell.dart';

export 'package:una_social/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SolidartConfig.devToolsEnabled = false;
  // The app has its own menus on a right click (posts, chats, photos); the
  // browser's would open over them.
  if (kIsWeb) await BrowserContextMenu.disableContextMenu();
  // una bundles no fonts. Fetch the app's face before the first frame, so
  // it does not open in the fallback font and then reflow; and load Liquid
  // Glass's shaders, so the first glass surfaces are not a frame late.
  await Future.wait([
    loadAppFont(timeout: const Duration(seconds: 3)),
    LiquidGlass.initialize(),
  ]);
  runApp(const App());
}

/// The weights the text roles use, fetched up front so the text reflows
/// once rather than once per weight.
const _weights = [
  FontWeight.w400,
  FontWeight.w500,
  FontWeight.w600,
  FontWeight.w700,
  FontWeight.w800,
];

/// Every text role in Plus Jakarta Sans: round and friendly at small sizes,
/// tight and confident in a headline. One object for the whole run; the
/// method is a static tear-off, so the theme compares equal however often
/// it is built.
final appTextTheme = TextTheme.fromGoogleFont(GoogleFonts.plusJakartaSans);

/// Fetches the faces and completes once they are registered, or when
/// fetching fails or is disabled (offline, tests): the text then renders in
/// the fallback face.
Future<void> loadAppFont({
  Duration timeout = const Duration(seconds: 5),
}) async {
  try {
    for (final weight in _weights) {
      GoogleFonts.plusJakartaSans(fontWeight: weight);
    }
    appTextTheme;
    await GoogleFonts.pendingFonts().timeout(timeout);
  } on Object {
    // Keep the fallback.
  }
}

/// The brand colour: an electric indigo, bright enough to read as social
/// and friendly, deep enough to carry white text.
const brandSeed = Color(0xFF5046E5);

/// The greys lean cool, towards slate, so the pages read crisp beside the
/// indigo rather than warm or muddy.
const brandNeutral = Color(0xFF64748B);

final _lightScheme = ColorScheme.fromSeed(brandSeed, neutral: brandNeutral);
final _darkScheme = ColorScheme.fromSeed(
  brandSeed,
  neutral: brandNeutral,
  brightness: Brightness.dark,
);

/// The package's default look (Fluid: soft glass, large radii, lively
/// motion) on the brand colours, built once per setting: an unequal theme
/// per build would be a theme change on every rebuild.
ThemeData themeFor(Brightness brightness, LiquidGlassMode mode) =>
    _themes[(brightness, mode)] ??= ThemeData(
      colorScheme: brightness == Brightness.dark ? _darkScheme : _lightScheme,
      textTheme: appTextTheme,
      liquidGlass: mode == LiquidGlassMode.auto
          ? null
          : LiquidGlassTheme(mode: mode),
    );

final _themes = <(Brightness, LiquidGlassMode), ThemeData>{};

/// Every app-level provider: the settings, the shell's destination and the
/// session. They sit above [UnaApp], so every route can read them.
final socialProviders = <InstantiableProvider>[
  ...appProviders,
  destinationProvider,
  sessionProvider,
];

/// Una Social: a fictional social network built from una's widgets.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      providers: socialProviders,
      child: SignalBuilder(
        builder: (context, _) {
          final themeMode = themeModeProvider.of(context).value;
          final textScale = textScaleProvider.of(context).value;
          final glass = liquidGlassProvider.of(context).value;
          return UnaApp(
            title: 'Una Social',
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            theme: themeFor(Brightness.light, glass),
            darkTheme: themeFor(Brightness.dark, glass),
            home: const SocialShell(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScale),
              ),
              child: child!,
            ),
          );
        },
      ),
    );
  }
}
