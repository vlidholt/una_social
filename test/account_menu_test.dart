import 'package:flutter_test/flutter_test.dart';

import 'support.dart';

void main() {
  setUpAll(setUpFonts);

  testWidgets('the account menu opens on a desktop', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.bySemanticsLabel('Your account'));
    await settle(tester, frames: 20);
    expect(find.text('Settings & privacy'), findsOneWidget);
    expect(find.text('Liquid Glass'), findsOneWidget);
  });
}
