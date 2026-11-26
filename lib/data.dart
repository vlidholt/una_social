import 'package:flutter/widgets.dart';
import 'package:una/una.dart';

/// The app's content: people, posts, groups, events, listings, chats and
/// notifications. Every person, group and business is fictional; the
/// photographs are from Unsplash (see `assets/images/README.md`).

String _img(String name) => 'assets/images/$name.jpg';

/// Someone on Una Social.
@immutable
class Person {
  const Person({
    required this.id,
    required this.name,
    required this.photo,
    required this.city,
    required this.work,
    this.mutual = 0,
    this.online = false,
    this.lastSeen,
  });

  final String id;
  final String name;

  /// An asset path.
  final String photo;
  final String city;
  final String work;

  /// Friends in common with you.
  final int mutual;
  final bool online;

  /// When an offline friend was last active ("12m").
  final String? lastSeen;

  String get firstName => name.split(' ').first;

  String get initials =>
      name.split(' ').map((part) => part.isEmpty ? '' : part[0]).take(2).join();
}

abstract final class People {
  static final me = Person(
    id: 'me',
    name: 'Alex Rivera',
    photo: _img('avatar_me'),
    city: 'Lisbon, Portugal',
    work: 'Product designer at Lumen Labs',
  );
  static final maya = Person(
    id: 'maya',
    name: 'Maya Lindqvist',
    photo: _img('avatar_maya'),
    city: 'Stockholm, Sweden',
    work: 'Photographer',
    mutual: 24,
    online: true,
  );
  static final jonas = Person(
    id: 'jonas',
    name: 'Jonas Weber',
    photo: _img('avatar_jonas'),
    city: 'Munich, Germany',
    work: 'Mountain guide at Alpenweg',
    mutual: 12,
    online: true,
  );
  static final hana = Person(
    id: 'hana',
    name: 'Hana Kim',
    photo: _img('avatar_hana'),
    city: 'Seoul, South Korea',
    work: 'Pastry chef at Maru Bakery',
    mutual: 8,
    lastSeen: '12m',
  );
  static final oliver = Person(
    id: 'oliver',
    name: 'Oliver Mensah',
    photo: _img('avatar_oliver'),
    city: 'Accra, Ghana',
    work: 'Engineer at Birchline',
    mutual: 31,
    online: true,
  );
  static final noah = Person(
    id: 'noah',
    name: 'Noah Fischer',
    photo: _img('avatar_noah'),
    city: 'Berlin, Germany',
    work: 'Studying architecture',
    mutual: 5,
    lastSeen: '1h',
  );
  static final ruth = Person(
    id: 'ruth',
    name: 'Ruth Alvarez',
    photo: _img('avatar_ruth'),
    city: 'Seville, Spain',
    work: 'Retired teacher',
    mutual: 3,
    online: true,
  );
  static final ines = Person(
    id: 'ines',
    name: 'Inès Laurent',
    photo: _img('avatar_ines'),
    city: 'Lyon, France',
    work: 'Ceramicist',
    mutual: 17,
    lastSeen: '3h',
  );
  static final samir = Person(
    id: 'samir',
    name: 'Samir Haddad',
    photo: _img('avatar_samir'),
    city: 'Amman, Jordan',
    work: 'Music producer',
    mutual: 9,
    online: true,
  );
  static final zara = Person(
    id: 'zara',
    name: 'Zara Okafor',
    photo: _img('avatar_zara'),
    city: 'Lagos, Nigeria',
    work: 'Illustrator',
    mutual: 14,
  );
  static final mei = Person(
    id: 'mei',
    name: 'Mei Chen',
    photo: _img('avatar_mei'),
    city: 'Taipei, Taiwan',
    work: 'Running coach',
    mutual: 6,
    lastSeen: '2d',
  );

  /// Your friends, in the order the contacts list shows them.
  static final friends = [maya, jonas, oliver, ruth, samir];

  /// People who asked to be your friend.
  static final requests = [zara, mei];

  /// People you may know.
  static final suggestions = [ines, hana, noah];

  static final all = [
    me,
    maya,
    jonas,
    hana,
    oliver,
    noah,
    ruth,
    ines,
    samir,
    zara,
    mei,
  ];

  static Person byId(String id) => all.firstWhere((person) => person.id == id);
}

/// The reactions a post takes.
enum Reaction {
  like('Like', PhosphorIconsFill.thumbsUp, Color(0xFF5046E5)),
  love('Love', PhosphorIconsFill.heart, Color(0xFFF43F5E)),
  care('Care', PhosphorIconsFill.handHeart, Color(0xFFF97316)),
  haha('Haha', PhosphorIconsFill.smileyWink, Color(0xFFF59E0B)),
  celebrate('Celebrate', PhosphorIconsFill.confetti, Color(0xFF8B5CF6)),
  sad('Sad', PhosphorIconsFill.smileySad, Color(0xFF0EA5E9));

  const Reaction(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}

@immutable
class Comment {
  const Comment({
    required this.author,
    required this.text,
    required this.age,
    this.likes = 0,
  });

  final Person author;
  final String text;
  final String age;
  final int likes;
}

/// A coloured background for a short text post.
enum PostBackdrop {
  sunset([Color(0xFFFB7185), Color(0xFF8B5CF6)]),
  ocean([Color(0xFF06B6D4), Color(0xFF4F46E5)]);

  const PostBackdrop(this.colors);
  final List<Color> colors;
}

@immutable
class Post {
  const Post({
    required this.id,
    required this.author,
    required this.age,
    required this.text,
    this.photos = const [],
    this.group,
    this.feeling,
    this.place,
    this.backdrop,
    this.reactions = const {},
    this.comments = const [],
    this.shares = 0,
    this.event,
  });

  final String id;
  final Person author;
  final String age;
  final String text;

  /// Asset paths.
  final List<String> photos;

  /// Posted in a group.
  final Group? group;

  /// "is feeling grateful".
  final String? feeling;

  /// "at Miradouro da Graça".
  final String? place;

  /// A short text post set large on a colour.
  final PostBackdrop? backdrop;

  /// How many of each reaction the post had before you came.
  final Map<Reaction, int> reactions;
  final List<Comment> comments;
  final int shares;

  /// A shared event.
  final Event? event;
}

@immutable
class Group {
  const Group({
    required this.id,
    required this.name,
    required this.cover,
    required this.members,
    required this.about,
    this.private = false,
    this.postsPerDay = 4,
  });

  final String id;
  final String name;
  final String cover;
  final String members;
  final String about;
  final bool private;
  final int postsPerDay;
}

abstract final class Groups {
  static final cooks = Group(
    id: 'cooks',
    name: 'Weekend Cooks',
    cover: _img('post_breakfast'),
    members: '48K',
    about: 'Slow breakfasts, long lunches and recipes worth a Saturday.',
    postsPerDay: 22,
  );
  static final trails = Group(
    id: 'trails',
    name: 'Alpine Trails Club',
    cover: _img('group_hikers'),
    members: '12K',
    about: 'Routes, gear and sunrise summits across the Alps.',
    postsPerDay: 9,
  );
  static final plants = Group(
    id: 'plants',
    name: 'Urban Jungle',
    cover: _img('group_plants'),
    members: '96K',
    about: 'Small flats, big leaves. Ask anything about houseplants.',
    postsPerDay: 41,
  );
  static final clay = Group(
    id: 'clay',
    name: 'Clay & Kiln',
    cover: _img('group_pottery'),
    members: '7.4K',
    about: 'Throwing, trimming, glazing — and the cracks that teach you.',
    private: true,
    postsPerDay: 5,
  );
  static final runners = Group(
    id: 'runners',
    name: 'Lisbon Run Crew',
    cover: _img('event_run'),
    members: '3.1K',
    about: 'Free group runs every Tuesday and Saturday along the river.',
    postsPerDay: 3,
  );

  static final all = [cooks, trails, plants, clay, runners];

  /// Groups you are in when the app opens.
  static final joined = {cooks.id, trails.id, runners.id};
}

@immutable
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.photo,
    required this.month,
    required this.day,
    required this.when,
    required this.where,
    required this.host,
    required this.going,
    required this.interested,
  });

  final String id;
  final String title;
  final String photo;
  final String month;
  final int day;
  final String when;
  final String where;
  final String host;
  final int going;
  final int interested;
}

abstract final class Events {
  static final festival = Event(
    id: 'festival',
    title: 'Northern Lights Festival',
    photo: _img('post_festival'),
    month: 'JUL',
    day: 12,
    when: 'Sat, Jul 12 · 18:00',
    where: 'Parque da Bela Vista, Lisbon',
    host: 'Samir Haddad',
    going: 2400,
    interested: 8100,
  );
  static final concert = Event(
    id: 'concert',
    title: 'Golden Hour Live: The Lanterns',
    photo: _img('event_concert'),
    month: 'JUN',
    day: 28,
    when: 'Sat, Jun 28 · 21:00',
    where: 'Coliseu dos Recreios, Lisbon',
    host: 'Coliseu Live',
    going: 860,
    interested: 3200,
  );
  static final run = Event(
    id: 'run',
    title: 'Riverside 10K — Saturday Group Run',
    photo: _img('event_run'),
    month: 'JUN',
    day: 21,
    when: 'Sat, Jun 21 · 08:00',
    where: 'Cais do Sodré, Lisbon',
    host: 'Lisbon Run Crew',
    going: 74,
    interested: 210,
  );
  static final pottery = Event(
    id: 'pottery',
    title: 'Open Studio: Wheel Basics',
    photo: _img('post_pottery'),
    month: 'JUL',
    day: 3,
    when: 'Thu, Jul 3 · 19:00',
    where: 'Atelier Barro, Lyon',
    host: 'Clay & Kiln',
    going: 18,
    interested: 64,
  );

  static final all = [run, concert, pottery, festival];
}

abstract final class Posts {
  static final all = <Post>[
    Post(
      id: 'lisbon',
      author: People.maya,
      age: '2h',
      place: 'Lisbon, Portugal',
      text:
          'Three days of trams, pastéis de nata and getting lost on purpose. '
          'Lisbon, you were worth every hill.',
      photos: [
        _img('post_lisbon_1'),
        _img('post_lisbon_2'),
        _img('post_lisbon_3'),
      ],
      reactions: {Reaction.love: 214, Reaction.like: 96, Reaction.care: 12},
      shares: 9,
      comments: [
        Comment(
          author: People.jonas,
          text: 'The light in the second one! Which street is that?',
          age: '1h',
          likes: 4,
        ),
        Comment(
          author: People.ruth,
          text: 'Come and visit Seville next time, cariño ☀️',
          age: '48m',
          likes: 11,
        ),
      ],
    ),
    Post(
      id: 'ridge',
      author: People.jonas,
      age: '5h',
      feeling: 'feeling on top of the world',
      group: Groups.trails,
      text:
          'Left the hut at 4:10, made the ridge just as the sun came over. '
          'Five of us, one thermos, zero regrets. Route notes in the comments.',
      photos: [_img('post_hike')],
      reactions: {
        Reaction.like: 388,
        Reaction.love: 120,
        Reaction.celebrate: 42,
      },
      shares: 31,
      comments: [
        Comment(
          author: People.mei,
          text: 'Adding this to the summer list. How long to the top?',
          age: '3h',
          likes: 2,
        ),
      ],
    ),
    Post(
      id: 'ship',
      author: People.oliver,
      age: '7h',
      backdrop: PostBackdrop.ocean,
      text: 'We shipped it. 14 months, 3 rewrites, 1 very patient team. 🚀',
      reactions: {
        Reaction.celebrate: 512,
        Reaction.like: 230,
        Reaction.love: 64,
      },
      shares: 18,
      comments: [
        Comment(
          author: People.samir,
          text: 'Huge, congrats to the whole team!',
          age: '6h',
          likes: 7,
        ),
      ],
    ),
    Post(
      id: 'brunch',
      author: People.hana,
      age: '9h',
      group: Groups.cooks,
      text:
          'Sunday brunch for eight: buttermilk waffles, jammy eggs and a '
          'yuzu curd I will be making every week now. Recipe below!',
      photos: [_img('post_brunch'), _img('post_breakfast')],
      reactions: {Reaction.love: 640, Reaction.like: 210, Reaction.haha: 4},
      shares: 77,
    ),
    Post(
      id: 'biscuit',
      author: People.noah,
      age: '1d',
      text:
          'Meet Biscuit. 9 weeks old, already owns the sofa, the bed and '
          'my heart.',
      photos: [_img('post_puppy'), _img('post_puppy_2')],
      reactions: {Reaction.love: 1200, Reaction.care: 340, Reaction.like: 410},
      shares: 22,
      comments: [
        Comment(
          author: People.hana,
          text: 'I need to meet Biscuit immediately.',
          age: '20h',
          likes: 19,
        ),
        Comment(
          author: People.zara,
          text: 'Those ears!! 😭',
          age: '18h',
          likes: 6,
        ),
      ],
    ),
    Post(
      id: 'festival',
      author: People.samir,
      age: '1d',
      text:
          'Six weeks to go. Who is coming? I am playing the late set on the '
          'second stage — come and say hi.',
      event: Events.festival,
      reactions: {Reaction.like: 98, Reaction.celebrate: 61},
      shares: 40,
    ),
    Post(
      id: 'wheel',
      author: People.ines,
      age: '2d',
      group: Groups.clay,
      text:
          'Week one at the wheel: seven bowls, four of them still bowls. '
          'Centring is a whole personality test.',
      photos: [_img('post_pottery')],
      reactions: {Reaction.like: 140, Reaction.haha: 38, Reaction.love: 29},
      shares: 3,
    ),
    Post(
      id: 'coast',
      author: People.me,
      age: '4d',
      place: 'Costa da Caparica',
      text:
          'Shot the whole roll on the coast road this weekend. Developing '
          'film is slow, and that is the point.',
      photos: [_img('cover_profile'), _img('market_camera')],
      reactions: {Reaction.love: 86, Reaction.like: 41},
      shares: 2,
      comments: [
        Comment(
          author: People.maya,
          text: 'The colours on this roll!! Which film?',
          age: '3d',
          likes: 3,
        ),
      ],
    ),
    Post(
      id: 'ruth',
      author: People.ruth,
      age: '3d',
      backdrop: PostBackdrop.sunset,
      text: 'Forty years of teaching and they still sent me flowers. Gracias, chicos.',
      reactions: {Reaction.love: 870, Reaction.care: 120, Reaction.like: 66},
      shares: 5,
    ),
  ];
}

@immutable
class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.price,
    required this.place,
    required this.photo,
    required this.seller,
    required this.category,
    required this.condition,
    required this.description,
    required this.listed,
  });

  final String id;
  final String title;
  final int price;
  final String place;
  final String photo;
  final Person seller;
  final String category;
  final String condition;
  final String description;
  final String listed;
}

abstract final class Market {
  static const categories = [
    'All',
    'Home',
    'Bikes',
    'Electronics',
    'Hobbies',
  ];

  static final all = [
    Listing(
      id: 'chair',
      title: 'Mid-century lounge chair',
      price: 180,
      place: 'Lisbon · 2 km',
      photo: _img('market_chair'),
      seller: People.ines,
      category: 'Home',
      condition: 'Used — like new',
      description:
          'Solid oak frame, mustard wool seat. No marks, no wobble. '
          'Pick-up in Graça.',
      listed: '3 hours ago',
    ),
    Listing(
      id: 'bike',
      title: 'Vintage city bike, 54 cm',
      price: 240,
      place: 'Lisbon · 4 km',
      photo: _img('market_bike'),
      seller: People.jonas,
      category: 'Bikes',
      condition: 'Used — good',
      description:
          'Steel frame, new tyres and chain this spring. Basket included.',
      listed: 'Yesterday',
    ),
    Listing(
      id: 'camera',
      title: 'Rangefinder film camera',
      price: 320,
      place: 'Porto · shipped',
      photo: _img('market_camera'),
      seller: People.maya,
      category: 'Electronics',
      condition: 'Used — very good',
      description:
          'Light meter works, shutter accurate at every speed. Comes with a '
          'roll of Portra 400.',
      listed: '2 days ago',
    ),
    Listing(
      id: 'sofa',
      title: 'Green velvet armchair',
      price: 150,
      place: 'Lisbon · 6 km',
      photo: _img('market_sofa'),
      seller: People.hana,
      category: 'Home',
      condition: 'Used — good',
      description: 'Deep, soft and very green. Cushion included.',
      listed: '4 days ago',
    ),
    Listing(
      id: 'radio',
      title: 'Restored 1960s radio',
      price: 95,
      place: 'Sintra · 18 km',
      photo: _img('market_radio'),
      seller: People.ruth,
      category: 'Electronics',
      condition: 'Refurbished',
      description:
          'Rewired with Bluetooth inside; the dial and the hum are original.',
      listed: 'Last week',
    ),
    Listing(
      id: 'wheel',
      title: 'Hand-thrown bowl set (4)',
      price: 60,
      place: 'Lyon · shipped',
      photo: _img('post_pottery'),
      seller: People.ines,
      category: 'Hobbies',
      condition: 'New',
      description: 'Stoneware, food safe, dishwasher friendly.',
      listed: 'Last week',
    ),
  ];
}

/// A story in the row at the top of the feed.
@immutable
class Story {
  const Story({required this.person, required this.photo, required this.age});

  final Person person;
  final String photo;
  final String age;
}

abstract final class Stories {
  static final all = [
    Story(person: People.maya, photo: _img('post_lisbon_2'), age: '2h'),
    Story(person: People.jonas, photo: _img('story_meadow'), age: '4h'),
    Story(person: People.samir, photo: _img('event_concert'), age: '6h'),
    Story(person: People.ruth, photo: _img('story_coast'), age: '9h'),
    Story(person: People.hana, photo: _img('post_breakfast'), age: '12h'),
    Story(person: People.noah, photo: _img('post_puppy_2'), age: '20h'),
  ];
}

/// Who has a birthday today.
abstract final class Birthdays {
  static final today = [People.oliver, People.ines];
}

/// The kinds of notification, each with its own badge.
enum NoticeKind {
  reaction(PhosphorIconsFill.heart, Color(0xFFF43F5E)),
  comment(PhosphorIconsFill.chatCircle, Color(0xFF22C55E)),
  friend(PhosphorIconsFill.userPlus, Color(0xFF5046E5)),
  group(PhosphorIconsFill.usersThree, Color(0xFF0EA5E9)),
  event(PhosphorIconsFill.calendarDot, Color(0xFFF97316)),
  birthday(PhosphorIconsFill.cake, Color(0xFFEC4899)),
  memory(PhosphorIconsFill.clockCounterClockwise, Color(0xFF8B5CF6));

  const NoticeKind(this.icon, this.color);
  final IconData icon;
  final Color color;
}

@immutable
class Notice {
  const Notice({
    required this.id,
    required this.kind,
    required this.text,
    required this.age,
    this.person,
    this.photo,
    this.target,
    this.earlier = false,
  });

  final String id;
  final NoticeKind kind;
  final Person? person;

  /// A picture to show in place of a person.
  final String? photo;

  /// The text after the person's name.
  final String text;
  final String age;

  /// What opening it shows: a post id, 'friends', 'events'.
  final String? target;

  /// Shown under "Earlier" rather than "New".
  final bool earlier;
}

abstract final class Notices {
  static final all = [
    Notice(
      id: 'n1',
      kind: NoticeKind.reaction,
      person: People.maya,
      text: 'and 38 others reacted to your photo.',
      age: '12m',
      target: 'profile',
    ),
    Notice(
      id: 'n2',
      kind: NoticeKind.friend,
      person: People.zara,
      text: 'sent you a friend request.',
      age: '1h',
      target: 'friends',
    ),
    Notice(
      id: 'n3',
      kind: NoticeKind.comment,
      person: People.jonas,
      text:
          'commented on Maya Lindqvist\'s post: "The light in the second one!"',
      age: '1h',
      target: 'lisbon',
    ),
    Notice(
      id: 'n4',
      kind: NoticeKind.birthday,
      person: People.oliver,
      text: 'has a birthday today. Wish him a good one!',
      age: '3h',
      target: 'birthday',
    ),
    Notice(
      id: 'n5',
      kind: NoticeKind.event,
      photo: _img('event_run'),
      text: 'Riverside 10K is this Saturday. 74 friends and neighbours are going.',
      age: '5h',
      target: 'events',
      earlier: true,
    ),
    Notice(
      id: 'n6',
      kind: NoticeKind.group,
      photo: _img('post_breakfast'),
      text: 'Hana Kim posted in Weekend Cooks: "Sunday brunch for eight…"',
      age: '9h',
      target: 'brunch',
      earlier: true,
    ),
    Notice(
      id: 'n7',
      kind: NoticeKind.memory,
      photo: _img('story_coast'),
      text: 'You have a memory from 3 years ago: the coast road with Ruth.',
      age: '1d',
      target: 'profile',
      earlier: true,
    ),
  ];
}

/// One message in a chat.
@immutable
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromMe,
    required this.text,
    this.time,
  });

  final String id;
  final bool fromMe;
  final String text;

  /// A time stamp shown above the message, when there is one.
  final String? time;
}

@immutable
class Chat {
  const Chat({
    required this.id,
    required this.person,
    required this.messages,
    required this.replies,
    this.unread = false,
  });

  final String id;
  final Person person;
  final List<ChatMessage> messages;

  /// What the other side answers, in turn.
  final List<String> replies;
  final bool unread;
}

abstract final class Chats {
  static final all = [
    Chat(
      id: 'maya',
      person: People.maya,
      unread: true,
      messages: const [
        ChatMessage(
          id: 'm1',
          fromMe: false,
          text: 'Back from Lisbon!',
          time: 'Today 09:12',
        ),
        ChatMessage(
          id: 'm2',
          fromMe: false,
          text: 'You were so right about Graça at sunset',
        ),
        ChatMessage(
          id: 'm3',
          fromMe: true,
          text: 'Told you 😄 did you find the bakery?',
        ),
        ChatMessage(
          id: 'm4',
          fromMe: false,
          text: 'Twice. Maybe three times. Coffee this week?',
        ),
      ],
      replies: const [
        'Perfect, Thursday works for me!',
        'I will bring the prints from the trip 📸',
      ],
    ),
    Chat(
      id: 'jonas',
      person: People.jonas,
      unread: true,
      messages: const [
        ChatMessage(
          id: 'j1',
          fromMe: false,
          text: 'Route notes for the ridge, as promised',
          time: 'Today 07:40',
        ),
        ChatMessage(
          id: 'j2',
          fromMe: false,
          text: 'Start before 4:30 or you will miss the light',
        ),
      ],
      replies: const [
        'Bring a headlamp and a warm layer, it is cold at the top.',
        'Let me know if you want to join in July!',
      ],
    ),
    Chat(
      id: 'oliver',
      person: People.oliver,
      messages: const [
        ChatMessage(
          id: 'o1',
          fromMe: true,
          text: 'Congrats on the launch!!',
          time: 'Yesterday 18:03',
        ),
        ChatMessage(
          id: 'o2',
          fromMe: false,
          text: 'Thank you! Drinks on me next time you are in town',
        ),
      ],
      replies: const ['Deal 🍻'],
    ),
    Chat(
      id: 'ruth',
      person: People.ruth,
      messages: const [
        ChatMessage(
          id: 'r1',
          fromMe: false,
          text: 'Did you get the photos I sent?',
          time: 'Mon 11:20',
        ),
        ChatMessage(id: 'r2', fromMe: true, text: 'I did, they are lovely ❤️'),
      ],
      replies: const ['Come for Sunday lunch soon, cariño.'],
    ),
    Chat(
      id: 'samir',
      person: People.samir,
      messages: const [
        ChatMessage(
          id: 's1',
          fromMe: false,
          text: 'Two guest-list spots for the festival, want them?',
          time: 'Sun 22:41',
        ),
      ],
      replies: const ['Done, you are on the list. Bring a friend!'],
    ),
  ];
}

/// Shortcuts in the desktop's left column and the phone's menu.
@immutable
class Shortcut {
  const Shortcut(this.label, this.icon, this.color, this.destination);

  final String label;
  final IconData icon;
  final Color color;

  /// The destination's name, or a page: 'saved', 'memories', 'settings'.
  final String destination;
}

const shortcuts = [
  Shortcut(
    'Friends',
    PhosphorIconsFill.usersThree,
    Color(0xFF5046E5),
    'friends',
  ),
  Shortcut('Groups', PhosphorIconsFill.usersFour, Color(0xFF0EA5E9), 'groups'),
  Shortcut(
    'Marketplace',
    PhosphorIconsFill.storefront,
    Color(0xFF14B8A6),
    'marketplace',
  ),
  Shortcut(
    'Events',
    PhosphorIconsFill.calendarStar,
    Color(0xFFF43F5E),
    'events',
  ),
  Shortcut(
    'Memories',
    PhosphorIconsFill.clockCounterClockwise,
    Color(0xFF8B5CF6),
    'memories',
  ),
  Shortcut(
    'Saved',
    PhosphorIconsFill.bookmarkSimple,
    Color(0xFFD946EF),
    'saved',
  ),
];
