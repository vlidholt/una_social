# Working notes for `una_social`

**Una Social** is a fictional social network built entirely from
[`una`](https://github.com/vlidholt/una) widgets: one of the example apps
that show the package in a real product. It deploys to
<https://vlidholt.github.io/una_social/> on every push to `main`.

`una`'s own `CLAUDE.md` is the reference for the package — theme
architecture, motion, glass, overlays, Flutter gotchas, test habits — and
the Demo (`vlidholt/una_demo`) is the sibling app these conventions come
from.

## Depending on una

- `pubspec.yaml` takes `una` from git (`main`); `pubspec.lock` pins the
  commit. Move it with `flutter pub upgrade una` and commit the lock.
- A **gitignored** `pubspec_overrides.yaml` points it at a local checkout.
  With it in place the lock records a path: never commit that lock.
- Only the public barrel (`package:una/una.dart`); no Material.

## The app

- `main.dart` builds the themes once per (brightness, Liquid Glass) pair:
  the default style on `ColorScheme.fromSeed(brandSeed, neutral:
  brandNeutral)`, text in Plus Jakarta Sans through a static
  `GoogleFonts` tear-off (never `getFont`). On the web it disables the
  browser's own context menu.
- `app_state.dart` holds the settings signals (theme mode, Liquid Glass,
  text scale); `navigation.dart` the `Destination` enum, its provider and
  `goTo`/`leaveTo`/`pushPage`; `session.dart` the `SocialSession`, a
  `ChangeNotifier` with everything the user changes that more than one
  screen shows (reactions, comments, posts, friendships, groups, RSVPs,
  saved things, notifications, chats and their replies). `context.social`
  reaches it.
- `shell.dart` is a `NavigationScaffold`: the top bar from 1024 wide
  (`SocialShell.topBarFrom`), otherwise the phone's app bar and the
  floating bottom bar — a tablet held upright gets the bottom bar too.
  Profiles, groups, listings, search, settings, saved, memories, photos,
  stories and (on a phone) conversations are pages pushed over the shell.
- The desktop Home has three columns that scroll on their own, under the
  bar, so the side columns stay put while the feed moves.
- `data.dart` is all the content. People are `People.*`; images are
  `assets/images/*.jpg`, credited in `assets/images/README.md`.

## Rules the screens follow

- Copy theme text styles (`theme.textTheme.small.copyWith(...)`), never a
  bare `TextStyle(fontWeight:)` for a whole text — inside a `TextSpan` of a
  styled `Text` is fine.
- **A `Button` lays its label out at its natural width.** A label that may
  not fit is a `ButtonLabel` (a `Flexible` text with an ellipsis) — except
  in a `Button(expands: true)`, which already wraps its child in an
  `Expanded`; a `Flexible` there is a parent-data error.
- Nothing is a dead end: a control with nowhere to go answers with a toast.
- **Photographs are `RevealImage`s** (`Photo` is one): a placeholder,
  then the exposure reveal. What the app can see coming is precached
  (`precachePhotos`) so it is simply there: the feed's photos and the
  stories while Home's skeletons show, the next two stories in the
  viewer, every page of the photo viewer. The viewer itself keeps
  `Image.asset`: its first photo was just on screen as a thumbnail. The
  faces in an `AvatarGroup` stay plain images.

## Tests

- `test/screens_test.dart` builds every destination and page at a phone's,
  a tablet's and a desktop's size, light and dark; an overflow fails it.
  Tests set text in the test font, which is wider than the real one, so a
  layout that passes there has room to spare.
- `test/interactions_test.dart` reacts, comments, posts, confirms and
  adds friends, joins a group, answers an event, chats and marks
  notifications read. A post's buttons are below the fold at 1440 × 900:
  `reveal` scrolls them to the middle first (at the top they would be
  under the bar).
- `pumpAndSettle` never returns here (skeletons, stories, typing); pump
  fixed frames with `settle`.
