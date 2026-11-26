import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/composer.dart';
import 'package:una_social/widgets/photo_viewer.dart';
import 'package:una_social/widgets/pieces.dart';
import 'package:una_social/widgets/post_card.dart';

/// Opens [person]'s profile over the shell.
Future<void> openProfile(BuildContext context, Person person) =>
    context.pushPage<void>((context) => ProfileScreen(person));

enum _ProfileTab { posts, about, friends, photos }

/// A profile: a tall cover photo that runs under the bar, the portrait
/// over its lower edge, the name, friends and actions, then the tabs.
///
/// On a desktop the posts tab has two columns — the intro, photos and
/// friends beside the posts; on a phone they stack.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen(this.person, {super.key});

  final Person person;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  _ProfileTab _tab = _ProfileTab.posts;

  bool get _isMe => widget.person == People.me;

  /// The photos on the profile: the person's own posts', then the
  /// pictures of the places they have been.
  List<String> get _photos {
    final own = [
      for (final post in Posts.all)
        if (post.author == widget.person) ...post.photos,
    ];
    return {
      ...own,
      'assets/images/story_coast.jpg',
      'assets/images/post_lisbon_1.jpg',
      'assets/images/story_meadow.jpg',
      'assets/images/post_hike.jpg',
      'assets/images/post_brunch.jpg',
      'assets/images/event_concert.jpg',
      'assets/images/post_lisbon_3.jpg',
      'assets/images/market_camera.jpg',
      'assets/images/post_puppy.jpg',
    }.toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final person = widget.person;
    return Scaffold(
      appBar: AppBar(
        surfaceBehavior: AppBarSurfaceBehavior.whenScrolled,
        title: Text(person.name),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.magnifyingGlass),
            semanticLabel: 'Search ${person.firstName}\'s posts',
            onPressed: () => showSocialToast(
              context,
              'Search in profile',
              description: 'Try the search page for now.',
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: context.social,
        builder: (context, _) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(person: person, isMe: _isMe),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: theme.margin),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TabBar<_ProfileTab>(
                          value: _tab,
                          onChanged: (tab) => setState(() => _tab = tab),
                          scrollable: theme.isPhone,
                          tabs: const [
                            Tab(value: _ProfileTab.posts, child: Text('Posts')),
                            Tab(value: _ProfileTab.about, child: Text('About')),
                            Tab(
                              value: _ProfileTab.friends,
                              child: Text('Friends'),
                            ),
                            Tab(
                              value: _ProfileTab.photos,
                              child: Text('Photos'),
                            ),
                          ],
                        ),
                        Gap.raw(theme.gap(GapSize.lg)),
                        ContentSwitch(
                          value: _tab,
                          child: KeyedSubtree(
                            key: ValueKey(_tab),
                            child: switch (_tab) {
                              _ProfileTab.posts => _PostsTab(
                                person: person,
                                isMe: _isMe,
                                photos: _photos,
                                onSeeAll: (tab) => setState(() => _tab = tab),
                              ),
                              _ProfileTab.about => _AboutCard(person: person),
                              _ProfileTab.friends => const _FriendsGrid(),
                              _ProfileTab.photos => _PhotoGridCard(
                                photos: _photos,
                                columns: theme.isPhone ? 3 : 4,
                              ),
                            },
                          ),
                        ),
                        SizedBox(
                          height:
                              theme.gap(GapSize.xl) +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The cover, the portrait, the name and the actions.
class _Header extends StatelessWidget {
  const _Header({required this.person, required this.isMe});

  final Person person;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final phone = theme.isPhone;
    final session = context.social;
    final top = MediaQuery.paddingOf(context).top;
    final coverHeight = (phone ? 260.0 : 400.0) + (phone ? top : 0);
    final portrait = phone ? 128.0 : 168.0;
    final friends = session.friends;

    final cover = Image.asset(
      isMe ? 'assets/images/cover_profile.jpg' : _coverFor(person),
      fit: BoxFit.cover,
      semanticLabel: '${person.firstName}\'s cover photo',
    );

    final actions = isMe
        ? [
            Button(
              leading: const PhosphorIcon(PhosphorIconsBold.plus),
              onPressed: () => showComposer(context, startWithPhoto: true),
              child: const ButtonLabel('Add to story'),
            ),
            Button.secondary(
              leading: const PhosphorIcon(PhosphorIconsFill.pencilSimple),
              onPressed: () => showSocialToast(
                context,
                'Edit profile',
                description: 'Your profile looks great as it is.',
              ),
              child: const ButtonLabel('Edit profile'),
            ),
          ]
        : [
            _FriendButton(person),
            Button.secondary(
              leading: const PhosphorIcon(PhosphorIconsFill.messengerLogo),
              onPressed: () {
                session.openChatWith(person);
                context.leaveTo(Destination.messages);
              },
              child: const ButtonLabel('Message'),
            ),
          ];

    final identity = Column(
      crossAxisAlignment: phone
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          person.name,
          textAlign: phone ? TextAlign.center : TextAlign.start,
          style: (phone ? theme.textTheme.h3 : theme.textTheme.h2).copyWith(
            color: scheme.foreground,
          ),
        ),
        const Gap.xs(),
        Text(
          isMe
              ? '${friends.length * 53 + 12} friends'
              : '${person.mutual} mutual friends',
          style: theme.textTheme.muted.copyWith(fontWeight: FontWeight.w600),
        ),
        const Gap.sm(),
        AvatarGroup(
          size: 32,
          children: [
            for (final friend in friends.take(7))
              Image.asset(friend.photo, fit: BoxFit.cover),
          ],
        ),
      ],
    );

    final inset = theme.margin + (phone ? 0 : 24);
    final overlap = portrait * (phone ? .5 : .4);
    final coverStack = Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: phone
              ? BorderRadius.zero
              : BorderRadius.vertical(bottom: theme.radii.xl.bottomLeft),
          child: SizedBox(
            height: coverHeight,
            width: double.infinity,
            child: cover,
          ),
        ),
        if (!phone)
          PositionedDirectional(
            end: 24,
            bottom: 16,
            child: Glass(
              level: GlassLevel.strong,
              borderRadius: theme.radii.full,
              child: Button.ghost(
                leading: const PhosphorIcon(PhosphorIconsFill.camera),
                onPressed: () => openPhotos(context, [
                  isMe ? 'assets/images/cover_profile.jpg' : _coverFor(person),
                ]),
                child: Text(isMe ? 'Edit cover photo' : 'View cover'),
              ),
            ),
          ),
        if (phone)
          Positioned(
            left: 0,
            right: 0,
            bottom: -overlap,
            child: Center(
              child: _Portrait(person: person, size: portrait),
            ),
          )
        else
          PositionedDirectional(
            start: inset,
            bottom: -overlap,
            child: _Portrait(person: person, size: portrait),
          ),
      ],
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            coverStack,
            if (phone)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  inset,
                  overlap + theme.gap(GapSize.sm),
                  inset,
                  theme.gap(GapSize.lg),
                ),
                child: Column(
                  children: [
                    identity,
                    const Gap.md(),
                    Row(
                      spacing: theme.gap(GapSize.sm),
                      children: [
                        for (final action in actions) Expanded(child: action),
                      ],
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsetsDirectional.fromSTEB(
                  inset + portrait + theme.gap(GapSize.lg),
                  theme.gap(GapSize.md),
                  inset,
                  theme.gap(GapSize.lg),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: identity),
                    const Gap.md(),
                    Row(spacing: theme.gap(GapSize.sm), children: actions),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _coverFor(Person person) => switch (person.id) {
    'jonas' => 'assets/images/post_hike.jpg',
    'maya' => 'assets/images/post_lisbon_1.jpg',
    'samir' => 'assets/images/post_festival.jpg',
    'hana' => 'assets/images/post_brunch.jpg',
    'ines' => 'assets/images/group_pottery.jpg',
    'noah' => 'assets/images/post_puppy_2.jpg',
    'mei' => 'assets/images/event_run.jpg',
    _ => 'assets/images/story_coast.jpg',
  };
}

class _Portrait extends StatelessWidget {
  const _Portrait({required this.person, required this.size});

  final Person person;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.background,
      ),
      child: PersonAvatar(person, size: size - 8),
    );
  }
}

/// Add friend, Requested or Friends, as you stand with [person].
class _FriendButton extends StatelessWidget {
  const _FriendButton(this.person);

  final Person person;

  @override
  Widget build(BuildContext context) {
    final session = context.social;
    return switch (session.friendshipWith(person)) {
      Friendship.friends => Button.secondary(
        leading: const PhosphorIcon(PhosphorIconsFill.userCheck),
        onPressed: () => showSocialToast(
          context,
          'You and ${person.firstName} are friends',
        ),
        child: const ButtonLabel('Friends'),
      ),
      Friendship.incoming => Button(
        leading: const PhosphorIcon(PhosphorIconsFill.userPlus),
        onPressed: () => session.confirm(person),
        child: const ButtonLabel('Confirm'),
      ),
      Friendship.requested => Button.secondary(
        leading: const PhosphorIcon(PhosphorIconsFill.userMinus),
        onPressed: () => session.cancelRequest(person),
        child: const ButtonLabel('Cancel request'),
      ),
      _ => Button(
        leading: const PhosphorIcon(PhosphorIconsFill.userPlus),
        onPressed: () => session.addFriend(person),
        child: const ButtonLabel('Add friend'),
      ),
    };
  }
}

class _PostsTab extends StatelessWidget {
  const _PostsTab({
    required this.person,
    required this.isMe,
    required this.photos,
    required this.onSeeAll,
  });

  final Person person;
  final bool isMe;
  final List<String> photos;
  final ValueChanged<_ProfileTab> onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posts = context.social.postsBy(person);
    final side = [
      _IntroCard(person: person),
      _PhotoGridCard(
        photos: photos.take(9).toList(),
        columns: 3,
        onSeeAll: () => onSeeAll(_ProfileTab.photos),
      ),
      _FriendsCard(onSeeAll: () => onSeeAll(_ProfileTab.friends)),
    ];
    final feed = [
      if (isMe) const ComposerCard(),
      if (posts.isEmpty)
        Card(
          child: Empty(
            icon: const PhosphorIcon(PhosphorIconsRegular.notePencil),
            title: const Text('No posts yet'),
            description: Text(
              isMe
                  ? 'Share what you are up to — it will show here.'
                  : '${person.firstName} has not posted anything yet.',
            ),
          ),
        ),
      for (final post in posts) PostCard(post, key: ValueKey(post.id)),
    ];
    final gap = theme.gap(GapSize.lg);
    if (theme.isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: [side.first, side[1], ...feed],
      );
    }
    final sideWidth = (MediaQuery.sizeOf(context).width * .4).clamp(
      300.0,
      380.0,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: gap,
      children: [
        SizedBox(
          width: sideWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: side,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: gap,
            children: feed,
          ),
        ),
      ],
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    Widget row(IconData icon, String text) => Row(
      children: [
        PhosphorIcon(icon, size: 20, color: scheme.mutedForeground),
        const Gap.sm(),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.small.copyWith(
              color: scheme.foreground,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
    return Card(
      title: const Text('Intro'),
      child: UnaColumn(
        gap: GapSize.md,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            person == People.me
                ? 'Designing calm software by day, chasing light with a film camera by weekend.'
                : 'Say hi — always up for a coffee and a good story.',
            textAlign: TextAlign.center,
            style: theme.textTheme.p.copyWith(color: scheme.foreground),
          ),
          row(PhosphorIconsFill.briefcase, person.work),
          row(PhosphorIconsFill.house, 'Lives in ${person.city}'),
          row(PhosphorIconsFill.heart, 'Single'),
          row(PhosphorIconsFill.clock, 'Joined March 2019'),
        ],
      ),
    );
  }
}

class _PhotoGridCard extends StatelessWidget {
  const _PhotoGridCard({
    required this.photos,
    required this.columns,
    this.onSeeAll,
  });

  final List<String> photos;
  final int columns;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      title: const Text('Photos'),
      action: onSeeAll == null
          ? null
          : Button.link(onPressed: onSeeAll, child: const Text('See all')),
      child: ClipRRect(
        borderRadius: theme.radii.lg,
        child: GridView.count(
          crossAxisCount: columns,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          children: [
            for (final (index, photo) in photos.indexed)
              Pressable(
                onPressed: () => openPhotos(context, photos, initial: index),
                semanticLabel: 'Photo ${index + 1}',
                builder: (context, states) => Image.asset(
                  photo,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FriendsCard extends StatelessWidget {
  const _FriendsCard({required this.onSeeAll});

  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friends = context.social.friends.take(6).toList();
    return Card(
      title: const Text('Friends'),
      description: Text('${context.social.friends.length * 53 + 12} friends'),
      action: Button.link(onPressed: onSeeAll, child: const Text('See all')),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: .78,
        children: [
          for (final friend in friends)
            Pressable(
              onPressed: () => openProfile(context, friend),
              semanticLabel: friend.name,
              builder: (context, states) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Photo(friend.photo, borderRadius: theme.radii.md),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.caption.copyWith(
                      color: theme.colorScheme.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    return ListSection(
      header: const Text('About'),
      children: [
        ListTile(
          leading: const PhosphorIcon(PhosphorIconsRegular.briefcase),
          title: Text(person.work),
          subtitle: const Text('Work'),
        ),
        ListTile(
          leading: const PhosphorIcon(PhosphorIconsRegular.house),
          title: Text(person.city),
          subtitle: const Text('Current city'),
        ),
        const ListTile(
          leading: PhosphorIcon(PhosphorIconsRegular.graduationCap),
          title: Text('Universidade de Lisboa'),
          subtitle: Text('Studied design'),
        ),
        const ListTile(
          leading: PhosphorIcon(PhosphorIconsRegular.translate),
          title: Text('English, Portuguese, Spanish'),
          subtitle: Text('Languages'),
        ),
      ],
    );
  }
}

class _FriendsGrid extends StatelessWidget {
  const _FriendsGrid();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final friends = context.social.friends;
    return ListSection(
      header: Text('${friends.length} friends'),
      children: [
        for (final friend in friends)
          ListTile(
            leading: PersonAvatar(friend, showOnline: true),
            title: Text(friend.name),
            subtitle: Text(friend.city),
            showChevron: !theme.isPhone,
            onTap: () => openProfile(context, friend),
          ),
      ],
    );
  }
}
