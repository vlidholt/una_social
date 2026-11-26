import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/screens/groups_screen.dart';
import 'package:una_social/screens/marketplace_screen.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/widgets/pieces.dart';

/// Search: recent searches until you type, then people, groups and
/// listings that match, as you type.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _recent = [
    'Maya Lindqvist',
    'Urban Jungle',
    'vintage bike',
    'Riverside 10K',
  ];

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(String text) =>
      text.toLowerCase().contains(_controller.text.trim().toLowerCase());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _controller.text.trim();
    final people = query.isEmpty
        ? const <Person>[]
        : People.all
              .where((person) => person != People.me && _matches(person.name))
              .toList();
    final groups = query.isEmpty
        ? const <Group>[]
        : Groups.all.where((group) => _matches(group.name)).toList();
    final listings = query.isEmpty
        ? const <Listing>[]
        : Market.all.where((listing) => _matches(listing.title)).toList();
    final nothing =
        query.isNotEmpty &&
        people.isEmpty &&
        groups.isEmpty &&
        listings.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: SearchField(
          controller: _controller,
          autofocus: true,
          placeholder: const Text('Search Una Social'),
          onCancel: () => Navigator.of(context).maybePop(),
          showCancel: theme.isPhone,
        ),
        actions: const [],
      ),
      body: PageContainer(
        scrollable: true,
        maxWidth: 680,
        child: UnaColumn(
          gap: GapSize.lg,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (query.isEmpty)
              ListSection(
                header: const Text('Recent'),
                headerTrailing: Button.link(
                  onPressed: _recent.isEmpty
                      ? null
                      : () => setState(_recent.clear),
                  child: const Text('Clear'),
                ),
                children: [
                  if (_recent.isEmpty)
                    const ListTile(title: Text('No recent searches')),
                  for (final term in _recent)
                    ListTile(
                      leading: const PhosphorIcon(
                        PhosphorIconsRegular.clockCounterClockwise,
                      ),
                      title: Text(term),
                      trailing: IconButton.ghost(
                        size: ButtonSize.sm,
                        icon: const PhosphorIcon(PhosphorIconsRegular.x),
                        semanticLabel: 'Remove $term',
                        onPressed: () => setState(() => _recent.remove(term)),
                      ),
                      onTap: () => _controller.text = term,
                    ),
                ],
              ),
            if (nothing)
              Card(
                child: Empty(
                  icon: const PhosphorIcon(
                    PhosphorIconsRegular.magnifyingGlass,
                  ),
                  title: const Text('No results'),
                  description: Text(
                    'Nothing matches "$query". Try a name or a group.',
                  ),
                ),
              ),
            if (people.isNotEmpty)
              ListSection(
                header: const Text('People'),
                children: [
                  for (final person in people)
                    ListTile(
                      leading: PersonAvatar(person, showOnline: true),
                      title: Text(person.name),
                      subtitle: Text(
                        '${person.mutual} mutual friends · ${person.city}',
                      ),
                      showChevron: true,
                      onTap: () => openProfile(context, person),
                    ),
                ],
              ),
            if (groups.isNotEmpty)
              ListSection(
                header: const Text('Groups'),
                children: [
                  for (final group in groups)
                    ListTile(
                      leading: SizedBox.square(
                        dimension: 40,
                        child: Photo(group.cover, borderRadius: theme.radii.md),
                      ),
                      title: Text(group.name),
                      subtitle: Text('${group.members} members'),
                      showChevron: true,
                      onTap: () => openGroup(context, group),
                    ),
                ],
              ),
            if (listings.isNotEmpty)
              ListSection(
                header: const Text('Marketplace'),
                children: [
                  for (final listing in listings)
                    ListTile(
                      leading: SizedBox.square(
                        dimension: 40,
                        child: Photo(
                          listing.photo,
                          borderRadius: theme.radii.md,
                        ),
                      ),
                      title: Text(listing.title),
                      subtitle: Text('€${listing.price} · ${listing.place}'),
                      showChevron: true,
                      onTap: () => openListing(context, listing),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
