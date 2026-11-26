import 'dart:async';

import 'package:disco/disco.dart';
import 'package:flutter/widgets.dart';
import 'package:una_social/data.dart';

/// Where you stand with someone.
enum Friendship {
  /// Friends already.
  friends,

  /// They asked; you have not answered.
  incoming,

  /// You asked; they have not answered.
  requested,

  /// Neither, and they are suggested to you.
  none,

  /// A suggestion or request you removed.
  dismissed,
}

/// Your answer to an event.
enum Rsvp { none, interested, going }

/// Everything the user changes that more than one screen shows: reactions
/// and comments, friendships, groups, events, saved things, notifications
/// and chats. One per app, provided above `UnaApp`.
class SocialSession extends ChangeNotifier {
  SocialSession({this.replyDelay = const Duration(milliseconds: 1400)}) {
    for (final person in People.friends) {
      _friendships[person.id] = Friendship.friends;
    }
    for (final person in People.requests) {
      _friendships[person.id] = Friendship.incoming;
    }
    for (final chat in Chats.all) {
      _messages[chat.id] = [...chat.messages];
      if (chat.unread) _unreadChats.add(chat.id);
    }
  }

  /// How long the other side of a chat takes to answer.
  final Duration replyDelay;
  final _timers = <Timer>[];
  bool _disposed = false;

  // ---- Posts -------------------------------------------------------------

  final _myReactions = <String, Reaction>{};
  final _myComments = <String, List<Comment>>{};
  final _myPosts = <Post>[];
  final _hiddenPosts = <String>{};
  final _savedPosts = <String>{};

  /// The feed: what you posted, newest first, then everyone else's.
  List<Post> get feed => [
    ..._myPosts,
    ...Posts.all.where((post) => !_hiddenPosts.contains(post.id)),
  ];

  /// The posts [person] wrote.
  List<Post> postsBy(Person person) => [
    ..._myPosts,
    ...Posts.all,
  ].where((post) => post.author == person).toList();

  Post? postById(String id) {
    for (final post in [..._myPosts, ...Posts.all]) {
      if (post.id == id) return post;
    }
    return null;
  }

  Reaction? reactionOf(Post post) => _myReactions[post.id];

  /// The post's reactions with yours counted in, largest first.
  List<MapEntry<Reaction, int>> reactionsOf(Post post) {
    final counts = {...post.reactions};
    final mine = _myReactions[post.id];
    if (mine != null) counts[mine] = (counts[mine] ?? 0) + 1;
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  int reactionCount(Post post) =>
      reactionsOf(post).fold(0, (sum, entry) => sum + entry.value);

  /// Reacts with [reaction], or takes your reaction back if it is the one
  /// you gave.
  void react(Post post, Reaction reaction) {
    if (_myReactions[post.id] == reaction) {
      _myReactions.remove(post.id);
    } else {
      _myReactions[post.id] = reaction;
    }
    notifyListeners();
  }

  /// The Like button: likes, or takes back whatever you reacted with.
  void toggleLike(Post post) {
    if (_myReactions.containsKey(post.id)) {
      _myReactions.remove(post.id);
    } else {
      _myReactions[post.id] = Reaction.like;
    }
    notifyListeners();
  }

  List<Comment> commentsOf(Post post) => [
    ...post.comments,
    ...?_myComments[post.id],
  ];

  void comment(Post post, String text) {
    (_myComments[post.id] ??= []).add(
      Comment(author: People.me, text: text, age: 'Just now'),
    );
    notifyListeners();
  }

  void publish(String text, {List<String> photos = const [], String? feeling}) {
    _myPosts.insert(
      0,
      Post(
        id: 'mine-${_myPosts.length}',
        author: People.me,
        age: 'Just now',
        text: text,
        photos: photos,
        feeling: feeling,
      ),
    );
    notifyListeners();
  }

  void hide(Post post) {
    _hiddenPosts.add(post.id);
    notifyListeners();
  }

  void unhide(Post post) {
    _hiddenPosts.remove(post.id);
    notifyListeners();
  }

  bool isSaved(Post post) => _savedPosts.contains(post.id);

  void toggleSaved(Post post) {
    if (!_savedPosts.remove(post.id)) _savedPosts.add(post.id);
    notifyListeners();
  }

  List<Post> get savedPosts =>
      feed.where((post) => _savedPosts.contains(post.id)).toList();

  // ---- People ------------------------------------------------------------

  final _friendships = <String, Friendship>{};

  Friendship friendshipWith(Person person) =>
      _friendships[person.id] ?? Friendship.none;

  void _setFriendship(Person person, Friendship value) {
    _friendships[person.id] = value;
    notifyListeners();
  }

  List<Person> get friends => People.all
      .where((person) => friendshipWith(person) == Friendship.friends)
      .toList();

  List<Person> get incomingRequests => People.requests
      .where((person) => friendshipWith(person) == Friendship.incoming)
      .toList();

  /// People you may know: not friends, not asked, not dismissed.
  List<Person> get suggestions => People.suggestions
      .where(
        (person) => switch (friendshipWith(person)) {
          Friendship.none || Friendship.requested => true,
          _ => false,
        },
      )
      .toList();

  void confirm(Person person) => _setFriendship(person, Friendship.friends);

  void decline(Person person) => _setFriendship(person, Friendship.dismissed);

  void addFriend(Person person) => _setFriendship(person, Friendship.requested);

  void cancelRequest(Person person) => _setFriendship(person, Friendship.none);

  void dismissSuggestion(Person person) =>
      _setFriendship(person, Friendship.dismissed);

  void restore(Person person, Friendship previous) =>
      _setFriendship(person, previous);

  // ---- Groups and events -------------------------------------------------

  final _joined = {...Groups.joined};
  final _rsvps = <String, Rsvp>{Events.run.id: Rsvp.going};

  bool isMember(Group group) => _joined.contains(group.id);

  void toggleMembership(Group group) {
    if (!_joined.remove(group.id)) _joined.add(group.id);
    notifyListeners();
  }

  List<Group> get myGroups => Groups.all.where(isMember).toList();

  Rsvp rsvpOf(Event event) => _rsvps[event.id] ?? Rsvp.none;

  void setRsvp(Event event, Rsvp value) {
    _rsvps[event.id] = value;
    notifyListeners();
  }

  // ---- Marketplace -------------------------------------------------------

  final _savedListings = <String>{};

  bool isListingSaved(Listing listing) => _savedListings.contains(listing.id);

  void toggleListingSaved(Listing listing) {
    if (!_savedListings.remove(listing.id)) _savedListings.add(listing.id);
    notifyListeners();
  }

  List<Listing> get savedListings => Market.all.where(isListingSaved).toList();

  // ---- Notifications -----------------------------------------------------

  final _readNotices = <String>{
    for (final notice in Notices.all)
      if (notice.earlier) notice.id,
  };

  bool isRead(Notice notice) => _readNotices.contains(notice.id);

  int get unreadNotices =>
      Notices.all.where((notice) => !isRead(notice)).length;

  void markRead(Notice notice) {
    if (_readNotices.add(notice.id)) notifyListeners();
  }

  void markAllRead() {
    _readNotices.addAll(Notices.all.map((notice) => notice.id));
    notifyListeners();
  }

  // ---- Chats -------------------------------------------------------------

  final _messages = <String, List<ChatMessage>>{};
  final _unreadChats = <String>{};
  final _typing = <String>{};
  final _replyIndex = <String, int>{};

  /// The chat on screen, whose replies arrive read.
  String? visibleChat;

  /// The conversation the Messages screen shows: a contact opens it from
  /// anywhere.
  final selectedChat = ValueNotifier<String?>(null);

  final _newChats = <Chat>[];

  List<Chat> get _allChats => [...Chats.all, ..._newChats];

  /// The conversation with [person], started if there is none.
  Chat chatWith(Person person) {
    for (final chat in _allChats) {
      if (chat.person == person) return chat;
    }
    final chat = Chat(
      id: person.id,
      person: person,
      messages: const [],
      replies: [
        'Hey ${People.me.firstName}! 👋',
        'Good to hear from you. Let\'s catch up soon!',
      ],
    );
    _newChats.add(chat);
    _messages[chat.id] = [];
    _lastActivity[chat.id] = ++_clock;
    return chat;
  }

  Chat? chatById(String? id) {
    for (final chat in _allChats) {
      if (chat.id == id) return chat;
    }
    return null;
  }

  /// Opens the conversation with [person] on the Messages screen.
  void openChatWith(Person person) {
    selectedChat.value = chatWith(person).id;
    notifyListeners();
  }

  List<ChatMessage> messagesOf(Chat chat) => _messages[chat.id]!;

  bool isUnread(Chat chat) => _unreadChats.contains(chat.id);

  bool isTyping(Chat chat) => _typing.contains(chat.id);

  int get unreadChats => _unreadChats.length;

  /// Chats with the latest first.
  List<Chat> get chats => _allChats
    ..sort((a, b) {
      final ai = _lastActivity[a.id] ?? -Chats.all.indexOf(a);
      final bi = _lastActivity[b.id] ?? -Chats.all.indexOf(b);
      return bi.compareTo(ai);
    });

  final _lastActivity = <String, int>{};
  int _clock = 0;

  void markChatRead(Chat chat) {
    if (_unreadChats.remove(chat.id)) notifyListeners();
  }

  /// Sends [text] to [chat]; the other side starts typing and answers.
  void send(Chat chat, String text) {
    final list = _messages[chat.id]!;
    list.add(
      ChatMessage(id: '${chat.id}-${list.length}', fromMe: true, text: text),
    );
    _lastActivity[chat.id] = ++_clock;
    notifyListeners();

    final index = _replyIndex[chat.id] ?? 0;
    if (index >= chat.replies.length) return;
    _replyIndex[chat.id] = index + 1;
    _later(replyDelay * .4, () {
      _typing.add(chat.id);
      notifyListeners();
    });
    _later(replyDelay, () {
      _typing.remove(chat.id);
      list.add(
        ChatMessage(
          id: '${chat.id}-${list.length}',
          fromMe: false,
          text: chat.replies[index],
        ),
      );
      _lastActivity[chat.id] = ++_clock;
      if (visibleChat != chat.id) _unreadChats.add(chat.id);
      notifyListeners();
    });
  }

  void _later(Duration delay, VoidCallback callback) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      if (!_disposed) callback();
    });
    _timers.add(timer);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final timer in _timers) {
      timer.cancel();
    }
    selectedChat.dispose();
    super.dispose();
  }
}

final sessionProvider = Provider<SocialSession>(
  (_) => SocialSession(),
  dispose: (session) => session.dispose(),
);

extension SocialSessionContext on BuildContext {
  /// The session above this context.
  SocialSession get social => sessionProvider.of(this);
}
