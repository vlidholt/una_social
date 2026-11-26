import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/screens/groups_screen.dart';
import 'package:una_social/screens/marketplace_screen.dart';
import 'package:una_social/screens/menu_screen.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/screens/search_screen.dart';
import 'package:una_social/screens/settings_screen.dart';
import 'package:una_social/widgets/photo_viewer.dart';
import 'package:una_social/widgets/stories.dart';

import 'support.dart';

/// Every destination and page builds at a phone's, a tablet's and a
/// desktop's size, light and dark, with nothing overflowing: an overflow
/// is reported as an error, which fails the test.
void main() {
  setUpAll(setUpFonts);

  final pages = <String, WidgetBuilder>{
    'my profile': (context) => ProfileScreen(People.me),
    'a friend\'s profile': (context) => ProfileScreen(People.jonas),
    'a stranger\'s profile': (context) => ProfileScreen(People.hana),
    'a group': (context) => GroupPage(Groups.trails),
    'a listing': (context) => ListingPage(Market.all.first),
    'search': (context) => const SearchScreen(),
    'settings': (context) => const SettingsScreen(),
    'saved': (context) => const SavedScreen(),
    'memories': (context) => const MemoriesScreen(),
    'photos': (context) => PhotoViewer(
      photos: Posts.all.first.photos,
      post: Posts.all.first,
    ),
    'stories': (context) => const StoryViewer(),
  };

  for (final (name, size) in [
    ('phone', phoneSize),
    ('tablet', tabletSize),
    ('desktop', desktopSize),
  ]) {
    for (final brightness in Brightness.values) {
      group('$name, ${brightness.name}', () {
        testWidgets('picks the right form factor', (tester) async {
          await pumpApp(tester, size: size, brightness: brightness);
          expect(
            formFactorOf(tester),
            size == phoneSize ? FormFactor.mobile : FormFactor.desktop,
          );
        });

        for (final destination in Destination.values) {
          testWidgets('${destination.name} builds', (tester) async {
            await pumpApp(tester, size: size, brightness: brightness);
            await goTo(tester, destination);
          });
        }

        for (final MapEntry(key: page, value: builder) in pages.entries) {
          testWidgets('$page builds', (tester) async {
            await pumpApp(tester, size: size, brightness: brightness);
            await push(tester, builder);
          });
        }
      });
    }
  }
}
