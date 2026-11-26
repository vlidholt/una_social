import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:una/una.dart';
import 'package:una_social/app_state.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/screens/events_screen.dart';
import 'package:una_social/screens/friends_screen.dart';
import 'package:una_social/screens/groups_screen.dart';
import 'package:una_social/screens/home_screen.dart';
import 'package:una_social/screens/marketplace_screen.dart';
import 'package:una_social/screens/menu_screen.dart';
import 'package:una_social/screens/messages_screen.dart';
import 'package:una_social/screens/notifications_screen.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/screens/search_screen.dart';
import 'package:una_social/screens/settings_screen.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/logo.dart';
import 'package:una_social/widgets/pieces.dart';

/// Una Social's chrome around the screen of the selected [Destination].
///
/// A [NavigationScaffold], so it follows the theme's form factor:
///
/// * **Desktop** — one app bar: the logo and a search pill, the five
///   destinations in the middle, then Messages, Notifications and your
///   account menu.
/// * **Phone** — a short app bar with the logo and search, notifications
///   and messages; a floating bottom bar with Home, Friends, Groups,
///   Marketplace and your menu.
///
/// Profiles, search, settings and conversations on a phone are pages
/// pushed over the shell.
class SocialShell extends StatelessWidget {
  const SocialShell({super.key});

  /// The width from which the destinations are in the top bar.
  static const topBarFrom = 1024.0;

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context, _) {
        final destination = destinationProvider.of(context).value;
        final session = context.social;
        return ListenableBuilder(
          listenable: session,
          builder: (context, _) {
            final theme = Theme.of(context);
            final portrait = (theme.navigationBarTheme.iconSize ?? 24) + 4;
            // A desktop's top bar holds the five destinations beside the
            // logo, the search pill and the account buttons from about a
            // landscape tablet's width. Narrower — a tablet held upright, a
            // small window — the destinations go to the floating bottom
            // bar and the bar is the phone's.
            return LayoutBuilder(
              builder: (context, constraints) => NavigationScaffold(
                layout: constraints.maxWidth >= SocialShell.topBarFrom
                    ? NavigationLayout.auto
                    : NavigationLayout.bottomBar,
                selectedIndex: destination.index,
                onDestinationSelected: (index) =>
                    context.goTo(Destination.values[index]),
                destinations: [
                  const NavigationDestination(
                    icon: PhosphorIcon(PhosphorIconsRegular.house),
                    selectedIcon: PhosphorIcon(PhosphorIconsFill.house),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: const PhosphorIcon(PhosphorIconsRegular.usersThree),
                    selectedIcon: const PhosphorIcon(
                      PhosphorIconsFill.usersThree,
                    ),
                    label: 'Friends',
                    badgeCount: session.incomingRequests.length,
                  ),
                  const NavigationDestination(
                    icon: PhosphorIcon(PhosphorIconsRegular.usersFour),
                    selectedIcon: PhosphorIcon(PhosphorIconsFill.usersFour),
                    label: 'Groups',
                  ),
                  const NavigationDestination(
                    icon: PhosphorIcon(PhosphorIconsRegular.storefront),
                    selectedIcon: PhosphorIcon(PhosphorIconsFill.storefront),
                    label: 'Marketplace',
                  ),
                  const NavigationDestination(
                    icon: PhosphorIcon(PhosphorIconsRegular.calendarStar),
                    selectedIcon: PhosphorIcon(PhosphorIconsFill.calendarStar),
                    label: 'Events',
                    showInBottomBar: false,
                  ),
                  NavigationDestination(
                    icon: const PhosphorIcon(PhosphorIconsRegular.bell),
                    selectedIcon: const PhosphorIcon(PhosphorIconsFill.bell),
                    label: 'Notifications',
                    badgeCount: session.unreadNotices,
                    showInTopBar: false,
                    showInBottomBar: false,
                  ),
                  NavigationDestination(
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.messengerLogo,
                    ),
                    selectedIcon: const PhosphorIcon(
                      PhosphorIconsFill.messengerLogo,
                    ),
                    label: 'Messages',
                    badgeCount: session.unreadChats,
                    showInTopBar: false,
                    showInBottomBar: false,
                  ),
                  NavigationDestination(
                    icon: PersonAvatar(People.me, size: portrait),
                    selectedIcon: _RingedPortrait(size: portrait),
                    label: 'Menu',
                    showInTopBar: false,
                  ),
                ],
                title: const _BarStart(),
                actions: [
                  _BarButton(
                    icon: PhosphorIconsFill.messengerLogo,
                    label: 'Messages',
                    count: session.unreadChats,
                    selected: destination == Destination.messages,
                    onPressed: () => context.goTo(Destination.messages),
                  ),
                  _BarButton(
                    icon: PhosphorIconsFill.bell,
                    label: 'Notifications',
                    count: session.unreadNotices,
                    selected: destination == Destination.notifications,
                    onPressed: () => context.goTo(Destination.notifications),
                  ),
                  const _AccountMenu(),
                ],
                mobileAppBar: _MobileAppBar(destination: destination),
                body: _Screens(destination: destination),
              ),
            );
          },
        );
      },
    );
  }
}

class _RingedPortrait extends StatelessWidget {
  const _RingedPortrait({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.tint, width: 2),
      ),
      child: PersonAvatar(People.me, size: size - 7),
    );
  }
}

/// The start of the desktop bar: the logo, then the search pill — which
/// gives up its text, and then the wordmark, as the window narrows.
class _BarStart extends StatelessWidget {
  const _BarStart();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = constraints.maxWidth;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SocialLogo(
              showWordmark: room >= 300,
              onPressed: () => context.goTo(Destination.home),
            ),
            const Gap.md(),
            Flexible(child: _SearchPill(compact: room < 240)),
          ],
        );
      },
    );
  }
}

/// "Search Una Social", a pill that opens search.
class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    void open() => context.pushPage<void>((context) => const SearchScreen());
    if (compact) {
      return IconButton.secondary(
        icon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass),
        semanticLabel: 'Search',
        onPressed: open,
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 260),
      child: Pressable(
        onPressed: open,
        semanticLabel: 'Search Una Social',
        builder: (context, states) => AnimatedFill(
          color: states.contains(WidgetState.hovered)
              ? scheme.secondary
              : scheme.muted,
          borderRadius: theme.radii.full,
          child: SizedBox(
            height: 40,
            child: Row(
              children: [
                const Gap.md(),
                PhosphorIcon(
                  PhosphorIconsRegular.magnifyingGlass,
                  size: 18,
                  color: scheme.mutedForeground,
                ),
                const Gap.sm(),
                Flexible(
                  child: Text(
                    'Search Una Social',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small.copyWith(
                      color: scheme.mutedForeground,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                const Gap.md(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A round button on the desktop bar with an unread count.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IndicatorBadge(
      count: count,
      semanticLabel: '$count unread',
      child: IconButton.secondary(
        size: ButtonSize.lg,
        style: ButtonTheme(
          backgroundColor: selected ? scheme.accent : scheme.muted,
          foregroundColor: selected ? scheme.tint : scheme.foreground,
          hoverBackgroundColor: selected ? scheme.accent : scheme.secondary,
        ),
        icon: PhosphorIcon(icon),
        semanticLabel: label,
        onPressed: onPressed,
      ),
    );
  }
}

/// Your portrait on the desktop bar, opening the account menu: your
/// profile, saved, settings, display and Liquid Glass.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = themeModeProvider.of(context).value == ThemeMode.dark;
    final glass = liquidGlassProvider.of(context);
    return DropdownMenu(
      items: [
        MenuItem(
          leading: PersonAvatar(People.me, size: 28),
          onPressed: () => openProfile(context, People.me),
          child: Text(People.me.name),
        ),
        const MenuDivider(),
        MenuItem(
          leading: const PhosphorIcon(PhosphorIconsRegular.bookmarkSimple),
          onPressed: () => openSaved(context),
          child: const Text('Saved'),
        ),
        MenuItem(
          leading: const PhosphorIcon(PhosphorIconsRegular.gearSix),
          onPressed: () =>
              context.pushPage<void>((context) => const SettingsScreen()),
          child: const Text('Settings & privacy'),
        ),
        MenuItem(
          leading: PhosphorIcon(
            dark ? PhosphorIconsRegular.sun : PhosphorIconsRegular.moon,
          ),
          onPressed: () => toggleThemeMode(context),
          child: Text(dark ? 'Light mode' : 'Dark mode'),
        ),
        MenuItem(
          leading: const PhosphorIcon(PhosphorIconsRegular.drop),
          items: [
            for (final mode in LiquidGlassMode.values)
              MenuItem(
                leading: mode == glass.value
                    ? const PhosphorIcon(PhosphorIconsBold.check)
                    : const SizedBox.square(dimension: 16),
                onPressed: () => glass.value = mode,
                child: Text(switch (mode) {
                  LiquidGlassMode.auto => 'Automatic',
                  LiquidGlassMode.always => 'On',
                  LiquidGlassMode.never => 'Off',
                }),
              ),
          ],
          child: const Text('Liquid Glass'),
        ),
        const MenuDivider(),
        MenuItem(
          leading: const PhosphorIcon(PhosphorIconsRegular.signOut),
          onPressed: () => showSocialToast(
            context,
            'This is a demo',
            description: 'There is nowhere to log out to. Stay a while!',
          ),
          child: const Text('Log out'),
        ),
      ],
      builder: (context, controller, child) => Pressable(
        onPressed: controller.toggle,
        semanticLabel: 'Your account',
        builder: (context, states) => FocusRing(
          visible: states.contains(WidgetState.focused),
          borderRadius: theme.radii.full,
          child: PersonAvatar(People.me, size: 40),
        ),
      ),
    );
  }
}

/// The phone's app bar: the logo, then search, notifications and
/// messages.
class _MobileAppBar extends StatelessWidget {
  const _MobileAppBar({required this.destination});

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.social;

    Widget action({
      required Destination target,
      required IconData icon,
      required IconData selectedIcon,
      required String label,
      required int count,
    }) {
      final selected = destination == target;
      return IndicatorBadge(
        count: count,
        overhang: 0,
        offset: const Offset(0, 2),
        semanticLabel: '$count unread',
        child: IconButton(
          icon: PhosphorIcon(selected ? selectedIcon : icon),
          style: ButtonTheme(
            foregroundColor: selected ? theme.colorScheme.tint : null,
          ),
          semanticLabel: label,
          onPressed: () => context.goTo(target),
        ),
      );
    }

    return AppBar(
      actionsGap: 0,
      leading: SocialLogo(onPressed: () => context.goTo(Destination.home)),
      actions: [
        IconButton(
          icon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass),
          semanticLabel: 'Search',
          onPressed: () =>
              context.pushPage<void>((context) => const SearchScreen()),
        ),
        action(
          target: Destination.notifications,
          icon: PhosphorIconsRegular.bell,
          selectedIcon: PhosphorIconsFill.bell,
          label: 'Notifications',
          count: session.unreadNotices,
        ),
        action(
          target: Destination.messages,
          icon: PhosphorIconsRegular.messengerLogo,
          selectedIcon: PhosphorIconsFill.messengerLogo,
          label: 'Messages',
          count: session.unreadChats,
        ),
      ],
    );
  }
}

/// The screens, one per destination, each kept alive once visited.
class _Screens extends StatelessWidget {
  const _Screens({required this.destination});

  final Destination destination;

  static Widget _screen(Destination destination) => switch (destination) {
    Destination.home => const HomeScreen(),
    Destination.friends => const FriendsScreen(),
    Destination.groups => const GroupsScreen(),
    Destination.marketplace => const MarketplaceScreen(),
    Destination.events => const EventsScreen(),
    Destination.notifications => const NotificationsScreen(),
    Destination.messages => const MessagesScreen(),
    Destination.menu => const MenuScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return DestinationStack(
      index: destination.index,
      builders: [
        for (final destination in Destination.values)
          (context) => _screen(destination),
      ],
    );
  }
}
