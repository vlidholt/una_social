import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:una/una.dart';
import 'package:una_social/main.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/shell.dart';

/// A desktop window and a phone.
const desktopSize = Size(1440, 900);
const tabletSize = Size(768, 1024);
const phoneSize = Size(375, 812);

/// The `setUpAll` of every test that builds the app: no font fetching in
/// tests, so the text is set in the test font.
Future<void> setUpFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
}

/// Pumps fixed frames: skeletons, stories and typing indicators animate
/// for as long as they show, so `pumpAndSettle` would never return.
Future<void> settle(WidgetTester tester, {int frames = 14}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Pumps the whole [App] in a window of [size], light or dark, past the
/// feed's first load.
Future<void> pumpApp(
  WidgetTester tester, {
  Size size = desktopSize,
  Brightness brightness = Brightness.light,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const App());
  if (brightness == Brightness.dark) {
    themeModeProvider.of(appContext(tester)).value = ThemeMode.dark;
  }
  await settle(tester, frames: 24);
}

/// A context below the app's providers and theme: the shell's, which stays
/// mounted under any page pushed over it.
BuildContext appContext(WidgetTester tester) =>
    tester.element(find.byType(SocialShell, skipOffstage: false));

/// Shows [destination] and waits out the switch.
Future<void> goTo(WidgetTester tester, Destination destination) async {
  appContext(tester).goTo(destination);
  await settle(tester);
}

/// Pushes [builder]'s page and waits out its entrance.
Future<void> push(WidgetTester tester, WidgetBuilder builder) async {
  appContext(tester).pushPage<void>(builder);
  await settle(tester, frames: 20);
}

/// The form factor the app chose.
FormFactor formFactorOf(WidgetTester tester) =>
    Theme.of(appContext(tester)).formFactor;
