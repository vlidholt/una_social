import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/post_card.dart';

import 'support.dart';

/// The things a visitor does: react, comment, post, answer requests, join
/// groups, answer events and chat.
void main() {
  setUpAll(setUpFonts);

  SocialSession sessionOf(WidgetTester tester) => appContext(tester).social;

  Finder firstPost() => find.byType(PostCard).first;

  Finder likeOfFirstPost() => find.descendant(
    of: find.byType(LikeButton).first,
    matching: find.text('Like'),
  );

  /// Scrolls [finder] to the middle of its scroll view: at the top it
  /// would be under the bar, which takes the tap.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await Scrollable.ensureVisible(tester.element(finder.first), alignment: .5);
    await settle(tester);
  }

  testWidgets('Like likes the post and a second tap takes it back', (
    tester,
  ) async {
    await pumpApp(tester);
    final post = sessionOf(tester).feed.first;
    final before = sessionOf(tester).reactionCount(post);

    await reveal(tester, likeOfFirstPost());
    await tester.tap(likeOfFirstPost());
    await settle(tester);
    expect(sessionOf(tester).reactionOf(post), Reaction.like);
    expect(sessionOf(tester).reactionCount(post), before + 1);
    expect(find.textContaining('You and'), findsWidgets);

    await tester.tap(
      likeOfFirstPost(),
    );
    await settle(tester);
    expect(sessionOf(tester).reactionOf(post), isNull);
  });

  testWidgets('a long press on Like opens the reactions', (tester) async {
    await pumpApp(tester);
    final post = sessionOf(tester).feed.first;
    await reveal(tester, likeOfFirstPost());
    await tester.longPress(
      likeOfFirstPost(),
    );
    await settle(tester, frames: 20);
    await tester.tap(find.bySemanticsLabel('Love').first);
    await settle(tester);
    expect(sessionOf(tester).reactionOf(post), Reaction.love);
  });

  testWidgets('a comment is added under the post', (tester) async {
    await pumpApp(tester);
    final field = find.descendant(
      of: firstPost(),
      matching: find.byType(EditableText),
    );
    await reveal(tester, field);
    await tester.enterText(field, 'Looks wonderful!');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await settle(tester);
    expect(find.text('Looks wonderful!'), findsOneWidget);
  });

  testWidgets('the composer publishes a post to the top of the feed', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.tap(find.text('What\'s on your mind, Alex?'));
    await settle(tester, frames: 20);
    await tester.enterText(
      find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(EditableText),
      ),
      'Hello from the test',
    );
    await settle(tester);
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Post')),
    );
    await settle(tester, frames: 30);
    expect(sessionOf(tester).feed.first.text, 'Hello from the test');
    expect(find.text('Hello from the test'), findsOneWidget);
  });

  testWidgets('confirming a request makes a friend', (tester) async {
    await pumpApp(tester);
    await goTo(tester, Destination.friends);
    final session = sessionOf(tester);
    expect(session.incomingRequests, hasLength(2));
    await tester.tap(find.text('Confirm').first);
    await settle(tester);
    expect(session.incomingRequests, hasLength(1));
    expect(session.friendshipWith(People.zara), Friendship.friends);
  });

  testWidgets('adding a suggestion sends a request', (tester) async {
    await pumpApp(tester);
    await goTo(tester, Destination.friends);
    await reveal(tester, find.text('Add friend'));
    await tester.tap(find.text('Add friend').first);
    await settle(tester);
    expect(
      sessionOf(tester).friendshipWith(People.suggestions.first),
      Friendship.requested,
    );
    expect(find.text('Requested'), findsOneWidget);
  });

  testWidgets('joining a group adds it to your groups', (tester) async {
    await pumpApp(tester);
    await goTo(tester, Destination.groups);
    final session = sessionOf(tester);
    expect(session.isMember(Groups.plants), isFalse);
    await tester.tap(find.text('Join').first);
    await settle(tester);
    expect(session.isMember(Groups.plants), isTrue);
  });

  testWidgets('Going answers an event', (tester) async {
    await pumpApp(tester);
    await goTo(tester, Destination.events);
    final session = sessionOf(tester);
    await tester.tap(find.text('Interested').at(1));
    await settle(tester);
    expect(session.rsvpOf(Events.all[0]), Rsvp.interested);
  });

  testWidgets('a message is answered', (tester) async {
    await pumpApp(tester);
    await goTo(tester, Destination.messages);
    final session = sessionOf(tester);
    final chat = Chats.all.first;
    final before = session.messagesOf(chat).length;
    await tester.enterText(find.byType(EditableText).last, 'See you Thursday');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await settle(tester);
    expect(session.messagesOf(chat).length, before + 1);
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(session.messagesOf(chat).length, before + 2);
    expect(session.messagesOf(chat).last.fromMe, isFalse);
  });

  testWidgets('Mark all read clears the bell', (tester) async {
    await pumpApp(tester);
    await goTo(tester, Destination.notifications);
    final session = sessionOf(tester);
    expect(session.unreadNotices, greaterThan(0));
    await tester.tap(find.text('Mark all read'));
    await settle(tester);
    expect(session.unreadNotices, 0);
  });

  testWidgets('a phone has the bottom bar and its own app bar', (tester) async {
    await pumpApp(tester, size: phoneSize);
    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.bySemanticsLabel('Search'), findsWidgets);
    await tester.tap(
      find.descendant(
        of: find.byType(BottomNavigationBar),
        matching: find.byIcon(PhosphorIconsRegular.usersThree),
      ),
    );
    await settle(tester);
    expect(
      destinationProvider.of(appContext(tester)).value,
      Destination.friends,
    );
  });
}
