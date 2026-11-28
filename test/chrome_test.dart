import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/widgets/logo.dart';
import 'package:una_social/widgets/side_columns.dart';

import 'support.dart';

/// The shell's bar against the page, and the pill fields' outlines.
void main() {
  setUpAll(setUpFonts);

  testWidgets('on a wide window the top bar is as wide as Home', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(2000, 1000));
    final logo = tester.getRect(find.byType(SocialLogo));
    final account = tester.getRect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(DropdownMenu),
      ),
    );
    final shortcuts = tester.getRect(find.byType(ShortcutsColumn));
    final contacts = tester.getRect(find.byType(ContactsColumn));
    expect(logo.left, moreOrLessEquals(shortcuts.left));
    expect(account.right, moreOrLessEquals(contacts.right));
  });

  /// The outline [field]'s decoration draws: its border and its focus
  /// ring, as the decorator resolves them over the theme's decoration.
  void expectPill(WidgetTester tester, Finder field) {
    // The field's own decorator is the outermost: its trailing button has
    // one of its own.
    final decorator = find
        .descendant(of: field, matching: find.byType(Decorator))
        .first;
    final height = tester.getSize(decorator).height;
    final theme = Theme.of(tester.element(decorator));
    final decoration = theme.decoration.merge(
      tester.widget<Decorator>(decorator).decoration,
    );
    for (final border in [
      decoration.border,
      decoration.secondaryFocusedBorder,
    ]) {
      final radius = border!.borderRadius!.resolve(TextDirection.ltr);
      for (final corner in [
        radius.topLeft,
        radius.topRight,
        radius.bottomLeft,
        radius.bottomRight,
      ]) {
        expect(corner.x, greaterThanOrEqualTo(height / 2));
      }
    }
  }

  testWidgets('the comment field and its focus ring are pills', (
    tester,
  ) async {
    await pumpApp(tester);
    expectPill(
      tester,
      find
          .ancestor(
            of: find.text('Write a comment…').first,
            matching: find.byType(TextField),
          )
          .first,
    );
  });

  testWidgets('the message composer and its focus ring are pills', (
    tester,
  ) async {
    await pumpApp(tester);
    await goTo(tester, Destination.messages);
    expectPill(
      tester,
      find.ancestor(of: find.text('Aa'), matching: find.byType(TextField)),
    );
  });
}
