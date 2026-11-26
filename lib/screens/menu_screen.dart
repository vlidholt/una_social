import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:una/una.dart';
import 'package:una_social/app_state.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/screens/marketplace_screen.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/screens/settings_screen.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/photo_viewer.dart';
import 'package:una_social/widgets/pieces.dart';
import 'package:una_social/widgets/post_card.dart';
import 'package:una_social/widgets/side_columns.dart';

/// The phone's last tab: you, the shortcuts as tiles, and the settings.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return PageContainer(
      scrollable: true,
      maxWidth: 720,
      child: UnaColumn(
        gap: GapSize.lg,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Gap.raw(theme.gap(GapSize.xs)),
          const PageTitle('Menu'),
          Card(
            style: CardTheme(padding: EdgeInsets.all(theme.gap(GapSize.md))),
            onTap: () => openProfile(context, People.me),
            semanticLabel: 'Your profile',
            child: Row(
              children: [
                PersonAvatar(People.me, size: 48),
                const Gap.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        People.me.name,
                        style: theme.textTheme.large.copyWith(
                          color: scheme.foreground,
                        ),
                      ),
                      Text('See your profile', style: theme.textTheme.muted),
                    ],
                  ),
                ),
                PhosphorIcon(
                  PhosphorIconsRegular.caretRight,
                  color: scheme.mutedForeground,
                ),
              ],
            ),
          ),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisExtent: 96,
              mainAxisSpacing: theme.gap(GapSize.sm),
              crossAxisSpacing: theme.gap(GapSize.sm),
            ),
            children: [
              for (final shortcut in shortcuts)
                Card(
                  style: CardTheme(
                    padding: EdgeInsets.all(theme.gap(GapSize.md)),
                  ),
                  onTap: () => openShortcut(context, shortcut),
                  semanticLabel: shortcut.label,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShortcutIcon(shortcut, size: 32),
                      Text(
                        shortcut.label,
                        style: theme.textTheme.small.copyWith(
                          color: scheme.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const _DisplaySection(),
          ListSection(
            children: [
              ListTile(
                leading: const PhosphorIcon(PhosphorIconsRegular.gearSix),
                title: const Text('Settings & privacy'),
                showChevron: true,
                onTap: () =>
                    context.pushPage<void>((context) => const SettingsScreen()),
              ),
              ListTile(
                leading: const PhosphorIcon(PhosphorIconsRegular.question),
                title: const Text('Help & support'),
                showChevron: true,
                onTap: () => showSocialToast(
                  context,
                  'Una Social is a demo',
                  description: 'Built with the una Flutter package.',
                ),
              ),
              ListTile(
                leading: const PhosphorIcon(PhosphorIconsRegular.signOut),
                title: const Text('Log out'),
                onTap: () => showSocialToast(
                  context,
                  'This is a demo',
                  description: 'There is nowhere to log out to. Stay a while!',
                ),
              ),
            ],
          ),
          const Gap.md(),
        ],
      ),
    );
  }
}

/// Dark mode and Liquid Glass, where a thumb finds them.
class _DisplaySection extends StatelessWidget {
  const _DisplaySection();

  @override
  Widget build(BuildContext context) {
    return SignalBuilder(
      builder: (context, _) {
        final mode = themeModeProvider.of(context);
        final glass = liquidGlassProvider.of(context);
        return ListSection(
          header: const Text('Display'),
          children: [
            SwitchListTile(
              secondary: const PhosphorIcon(PhosphorIconsRegular.moon),
              title: const Text('Dark mode'),
              value: mode.value == ThemeMode.dark,
              onChanged: (dark) =>
                  mode.value = dark ? ThemeMode.dark : ThemeMode.light,
            ),
            SwitchListTile(
              secondary: const PhosphorIcon(PhosphorIconsRegular.drop),
              title: const Text('Liquid Glass'),
              subtitle: const Text('Off shows what other platforms get'),
              value: glass.value != LiquidGlassMode.never,
              onChanged: (on) => glass.value = on
                  ? LiquidGlassMode.auto
                  : LiquidGlassMode.never,
            ),
          ],
        );
      },
    );
  }
}

/// Opens what you saved: posts and listings.
Future<void> openSaved(BuildContext context) =>
    context.pushPage<void>((context) => const SavedScreen());

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.social;
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: ListenableBuilder(
        listenable: session,
        builder: (context, _) {
          final posts = session.savedPosts;
          final listings = session.savedListings;
          return PageContainer(
            scrollable: true,
            maxWidth: 720,
            child: UnaColumn(
              gap: GapSize.lg,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (posts.isEmpty && listings.isEmpty)
                  Card(
                    child: Empty(
                      icon: const PhosphorIcon(
                        PhosphorIconsRegular.bookmarkSimple,
                      ),
                      title: const Text('Nothing saved yet'),
                      description: const Text(
                        'Save posts from their menu and listings with the heart; they will wait for you here.',
                      ),
                      actions: [
                        Button.outline(
                          onPressed: () =>
                              context.leaveTo(Destination.marketplace),
                          child: const ButtonLabel('Browse Marketplace'),
                        ),
                      ],
                    ),
                  ),
                if (listings.isNotEmpty)
                  ListSection(
                    header: const Text('Listings'),
                    children: [
                      for (final listing in listings)
                        ListTile(
                          leading: SizedBox.square(
                            dimension: 48,
                            child: Photo(
                              listing.photo,
                              borderRadius: theme.radii.md,
                            ),
                          ),
                          title: Text(listing.title),
                          subtitle: Text(
                            '€${listing.price} · ${listing.place}',
                          ),
                          showChevron: true,
                          onTap: () => openListing(context, listing),
                        ),
                    ],
                  ),
                for (final post in posts)
                  PostCard(post, key: ValueKey(post.id)),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Opens "On this day": a memory from years ago.
Future<void> openMemories(BuildContext context) =>
    context.pushPage<void>((context) => const MemoriesScreen());

class MemoriesScreen extends StatelessWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const photos = [
      'assets/images/story_coast.jpg',
      'assets/images/cover_profile.jpg',
      'assets/images/post_lisbon_3.jpg',
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Memories')),
      body: PageContainer(
        scrollable: true,
        maxWidth: 680,
        child: UnaColumn(
          gap: GapSize.lg,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'On this day',
              style: theme.textTheme.h2.copyWith(color: scheme.foreground),
            ),
            Text(
              '3 years ago, you and Ruth drove the coast road south of Lisbon.',
              style: theme.textTheme.lead,
            ),
            Card(
              style: const CardTheme(padding: EdgeInsets.zero),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Pressable(
                    onPressed: () => openPhotos(context, photos),
                    semanticLabel: 'Open photos',
                    builder: (context, states) => Photo(
                      photos.first,
                      aspectRatio: 4 / 3,
                      borderRadius: BorderRadius.vertical(
                        top: theme.radii.xl.topLeft,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(theme.gap(GapSize.lg)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Share this memory with Ruth?',
                            style: theme.textTheme.small.copyWith(
                              color: scheme.foreground,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Button(
                          leading: const PhosphorIcon(
                            PhosphorIconsRegular.shareFat,
                          ),
                          onPressed: () => showSocialToast(
                            context,
                            'Memory shared with Ruth',
                            variant: ToastVariant.success,
                          ),
                          child: const Text('Share'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
