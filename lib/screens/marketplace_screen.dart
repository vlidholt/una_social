import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/photo_viewer.dart';
import 'package:una_social/widgets/pieces.dart';

/// The Marketplace destination: what is for sale near you, by category,
/// in a grid of photos and prices.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _category = Market.categories.first;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listings = Market.all
        .where(
          (listing) =>
              (_category == 'All' || listing.category == _category) &&
              listing.title.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();

    return PageContainer(
      scrollable: true,
      maxWidth: 1180,
      child: UnaColumn(
        gap: GapSize.lg,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (theme.isPhone) Gap.raw(theme.gap(GapSize.xs)),
          PageTitle(
            'Marketplace',
            subtitle: 'Lisbon · within 20 km',
            actions: [
              if (!theme.isPhone)
                SizedBox(
                  width: 260,
                  child: SearchField(
                    placeholder: const Text('Search Marketplace'),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              Button(
                leading: const PhosphorIcon(PhosphorIconsBold.plus),
                onPressed: () => showSocialToast(
                  context,
                  'Listing drafts are coming soon',
                  description:
                      'Browse what your neighbours are selling for now.',
                ),
                child: Text(theme.isPhone ? 'Sell' : 'Create listing'),
              ),
            ],
          ),
          if (theme.isPhone)
            SearchField(
              placeholder: const Text('Search Marketplace'),
              onChanged: (value) => setState(() => _query = value),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            child: ChipGroup<String>(
              value: _category,
              onChanged: (value) => setState(() => _category = value ?? 'All'),
              items: [
                for (final category in Market.categories)
                  ChipGroupItem(value: category, label: Text(category)),
              ],
            ),
          ),
          if (listings.isEmpty)
            Card(
              child: Empty(
                icon: const PhosphorIcon(PhosphorIconsRegular.storefront),
                title: const Text('Nothing here yet'),
                description: const Text('Try another category or search.'),
                actions: [
                  Button.outline(
                    onPressed: () => setState(() {
                      _category = 'All';
                      _query = '';
                    }),
                    child: const Text('Show everything'),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final gap = theme.gap(theme.isPhone ? GapSize.sm : GapSize.md);
                final columns = theme.isPhone
                    ? 2
                    : (constraints.maxWidth / 260).floor().clamp(2, 5);
                final width =
                    (constraints.maxWidth - gap * (columns - 1)) / columns;
                return Wrap(
                  spacing: gap,
                  runSpacing: theme.gap(GapSize.lg),
                  children: [
                    for (final listing in listings)
                      SizedBox(
                        key: ValueKey(listing.id),
                        width: width,
                        child: Entrance(child: ListingTile(listing)),
                      ),
                  ],
                );
              },
            ),
          const Gap.md(),
        ],
      ),
    );
  }
}

/// A listing in the grid: the photo with a save button, the price, the
/// title and where it is.
class ListingTile extends StatelessWidget {
  const ListingTile(this.listing, {super.key});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Pressable(
      onPressed: () => openListing(context, listing),
      semanticLabel: '${listing.title}, €${listing.price}',
      builder: (context, states) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: theme.radii.xl,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: AnimatedScale(
                    scale: states.contains(WidgetState.hovered) ? 1.04 : 1,
                    duration: Motion.of(context).normal,
                    curve: Motion.of(context).standard,
                    child: RevealImage.asset(listing.photo, fit: BoxFit.cover),
                  ),
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: _SaveButton(listing),
              ),
            ],
          ),
          const Gap.sm(),
          Text(
            '€${listing.price}',
            style: theme.textTheme.large.copyWith(
              color: scheme.foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            listing.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(
              color: scheme.foreground,
              fontWeight: FontWeight.w400,
            ),
          ),
          Text(listing.place, style: theme.textTheme.caption),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton(this.listing);

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: context.social,
      builder: (context, _) {
        final saved = context.social.isListingSaved(listing);
        return Glass(
          level: GlassLevel.strong,
          borderRadius: theme.radii.full,
          child: IconButton.ghost(
            size: ButtonSize.sm,
            icon: PopIn(
              key: ValueKey(saved),
              visible: true,
              child: PhosphorIcon(
                saved ? PhosphorIconsFill.heart : PhosphorIconsBold.heart,
                color: saved ? Reaction.love.color : null,
              ),
            ),
            semanticLabel: saved
                ? 'Unsave ${listing.title}'
                : 'Save ${listing.title}',
            onPressed: () => context.social.toggleListingSaved(listing),
          ),
        );
      },
    );
  }
}

/// Opens [listing]'s page over the shell.
Future<void> openListing(BuildContext context, Listing listing) =>
    context.pushPage<void>((context) => ListingPage(listing));

/// A listing: the photo, the price, the details and the seller, with
/// Message and Save.
class ListingPage extends StatelessWidget {
  const ListingPage(this.listing, {super.key});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = context.social;
    final phone = theme.isPhone;

    final photo = Pressable(
      onPressed: () => openPhotos(context, [listing.photo]),
      semanticLabel: 'View photo',
      builder: (context, states) => Photo(
        listing.photo,
        aspectRatio: phone ? 1 : 1.1,
        borderRadius: phone ? BorderRadius.zero : theme.radii.xl,
      ),
    );

    final details = ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final saved = session.isListingSaved(listing);
        return UnaColumn(
          gap: GapSize.lg,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  listing.title,
                  style: theme.textTheme.h3.copyWith(color: scheme.foreground),
                ),
                const Gap.xs(),
                Text(
                  '€${listing.price}',
                  style: theme.textTheme.h3.copyWith(
                    color: scheme.tint,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Gap.xs(),
                Text(
                  'Listed ${listing.listed} in ${listing.place}',
                  style: theme.textTheme.muted,
                ),
              ],
            ),
            Row(
              spacing: theme.gap(GapSize.sm),
              children: [
                Expanded(
                  child: Button(
                    leading: const PhosphorIcon(
                      PhosphorIconsFill.messengerLogo,
                    ),
                    onPressed: () {
                      session.openChatWith(listing.seller);
                      context.leaveTo(Destination.messages);
                    },
                    child: const ButtonLabel('Message seller'),
                  ),
                ),
                Button.secondary(
                  leading: PhosphorIcon(
                    saved
                        ? PhosphorIconsFill.heart
                        : PhosphorIconsRegular.heart,
                    color: saved ? Reaction.love.color : null,
                  ),
                  onPressed: () => session.toggleListingSaved(listing),
                  child: ButtonLabel(saved ? 'Saved' : 'Save'),
                ),
              ],
            ),
            ListSection(
              header: const Text('Details'),
              children: [
                ListTile(
                  title: const Text('Condition'),
                  value: Text(listing.condition),
                ),
                ListTile(
                  title: const Text('Category'),
                  value: Text(listing.category),
                ),
              ],
            ),
            Text(
              listing.description,
              style: theme.textTheme.p.copyWith(color: scheme.foreground),
            ),
            ListSection(
              header: const Text('Seller'),
              children: [
                ListTile(
                  leading: PersonAvatar(listing.seller),
                  title: Text(listing.seller.name),
                  subtitle: const Text(
                    'Joined 2019 · Usually responds within an hour',
                  ),
                  showChevron: true,
                  onTap: () => openProfile(context, listing.seller),
                ),
              ],
            ),
          ],
        );
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: phone
          ? ListView(
              padding: EdgeInsets.zero,
              children: [
                photo,
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    theme.margin,
                    theme.gap(GapSize.lg),
                    theme.margin,
                    theme.gap(GapSize.xl) +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  child: details,
                ),
              ],
            )
          : PageContainer(
              scrollable: true,
              maxWidth: 1080,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: theme.gap(GapSize.xl),
                children: [
                  Expanded(flex: 3, child: photo),
                  Expanded(flex: 2, child: details),
                ],
              ),
            ),
    );
  }
}
