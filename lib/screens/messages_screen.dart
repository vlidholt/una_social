import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/pieces.dart';

/// The Messages destination: your conversations, and the one you are in.
///
/// A desktop shows both side by side; a phone shows the list and pushes a
/// conversation as its own page, with its own bar and no bottom bar.
class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.social;
    return FormFactorBuilder(
      mobile: (context) => const _PhoneMessages(),
      desktop: (context) => ValueListenableBuilder(
        valueListenable: session.selectedChat,
        builder: (context, selected, _) {
          final chat = session.chatById(selected) ?? session.chats.first;
          return PageContainer(
            maxWidth: 1180,
            child: Card(
              style: const CardTheme(padding: EdgeInsets.zero),
              child: ClipRRect(
                borderRadius: Theme.of(context).radii.xl,
                child: ListDetailLayout(
                  listWidth: 340,
                  list: _ChatsList(
                    selected: chat,
                    onSelected: (chat) => session.selectedChat.value = chat.id,
                  ),
                  detail: Thread(chat, key: ValueKey(chat.id)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A phone's list; a conversation opens as a page. One the rest of the
/// app asked to open (from a profile, a listing) opens at once.
class _PhoneMessages extends StatefulWidget {
  const _PhoneMessages();

  @override
  State<_PhoneMessages> createState() => _PhoneMessagesState();
}

class _PhoneMessagesState extends State<_PhoneMessages> {
  late final SocialSession _session = context.social;

  @override
  void initState() {
    super.initState();
    _session.selectedChat.addListener(_openRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openRequested());
  }

  @override
  void dispose() {
    _session.selectedChat.removeListener(_openRequested);
    super.dispose();
  }

  void _openRequested() {
    final chat = _session.chatById(_session.selectedChat.value);
    if (chat == null || !mounted || !TickerMode.valuesOf(context).enabled) {
      return;
    }
    _session.selectedChat.value = null;
    _open(chat);
  }

  void _open(Chat chat) => context.pushPage<void>(
    (context) => Scaffold(
      appBar: AppBar(
        title: _ThreadTitle(chat),
        actions: [
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.phone),
            semanticLabel: 'Voice call',
            onPressed: () => _call(context, chat, video: false),
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsRegular.videoCamera),
            semanticLabel: 'Video call',
            onPressed: () => _call(context, chat, video: true),
          ),
        ],
      ),
      resizeToAvoidBottomInset: true,
      body: Thread(chat, showHeader: false),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return _ChatsList(selected: null, onSelected: _open);
  }
}

void _call(BuildContext context, Chat chat, {required bool video}) =>
    showSocialToast(
      context,
      '${video ? 'Video calling' : 'Calling'} ${chat.person.firstName}…',
      description: 'Calls are not part of the demo.',
    );

/// The conversations, latest first, with a search field and the people
/// online across the top.
class _ChatsList extends StatefulWidget {
  const _ChatsList({required this.selected, required this.onSelected});

  final Chat? selected;
  final ValueChanged<Chat> onSelected;

  @override
  State<_ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends State<_ChatsList> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = context.social;
    final phone = theme.isPhone;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final chats = session.chats
            .where(
              (chat) => chat.person.name.toLowerCase().contains(
                _query.toLowerCase(),
              ),
            )
            .toList();
        final online = session.friends
            .where((person) => person.online)
            .toList();
        final margin = phone ? theme.margin : theme.gap(GapSize.md);
        return ListView(
          padding: phone
              ? null
              : EdgeInsets.symmetric(vertical: theme.gap(GapSize.md)),
          children: [
            if (phone) Gap.raw(theme.gap(GapSize.sm)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: margin),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chats',
                      style: (phone ? theme.textTheme.h3 : theme.textTheme.h4)
                          .copyWith(color: scheme.foreground),
                    ),
                  ),
                  IconButton.secondary(
                    size: ButtonSize.sm,
                    icon: const PhosphorIcon(PhosphorIconsRegular.notePencil),
                    semanticLabel: 'New message',
                    onPressed: () => _newMessage(context),
                  ),
                ],
              ),
            ),
            const Gap.sm(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: margin),
              child: SearchField(
                placeholder: const Text('Search Messenger'),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (_query.isEmpty) ...[
              const Gap.md(),
              SizedBox(
                height: 84,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: margin),
                  itemCount: online.length,
                  separatorBuilder: (context, index) => const Gap.md(),
                  itemBuilder: (context, index) {
                    final person = online[index];
                    return Pressable(
                      onPressed: () =>
                          widget.onSelected(session.chatWith(person)),
                      semanticLabel: 'Chat with ${person.name}',
                      builder: (context, states) => SizedBox(
                        width: 58,
                        child: Column(
                          children: [
                            PersonAvatar(person, size: 52, showOnline: true),
                            const SizedBox(height: 4),
                            Text(
                              person.firstName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.caption.copyWith(
                                color: scheme.foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const Gap.sm(),
            if (chats.isEmpty)
              Padding(
                padding: EdgeInsets.all(margin),
                child: Empty(
                  icon: const PhosphorIcon(PhosphorIconsRegular.chatsCircle),
                  title: const Text('No chats found'),
                  description: Text('Nobody called "$_query" in your chats.'),
                ),
              ),
            for (final chat in chats)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: margin - 8),
                child: _ChatRow(
                  chat,
                  selected: chat == widget.selected,
                  onPressed: () {
                    session.markChatRead(chat);
                    widget.onSelected(chat);
                  },
                ),
              ),
            if (phone) const Gap.xl(),
          ],
        );
      },
    );
  }

  void _newMessage(BuildContext context) async {
    final session = context.social;
    final person = await showActionSheet<Person>(
      context: context,
      title: const Text('New message'),
      actions: [
        for (final person in session.friends)
          ActionSheetAction(
            label: Text(person.name),
            icon: PersonAvatar(person, size: 24),
            value: person,
          ),
      ],
    );
    if (person != null && context.mounted) {
      widget.onSelected(session.chatWith(person));
    }
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow(this.chat, {required this.selected, required this.onPressed});

  final Chat chat;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = context.social;
    final messages = session.messagesOf(chat);
    final last = messages.isEmpty ? null : messages.last;
    final unread = session.isUnread(chat);
    final typing = session.isTyping(chat);
    final preview = typing
        ? 'Typing…'
        : last == null
        ? 'Say hi to ${chat.person.firstName} 👋'
        : '${last.fromMe ? 'You: ' : ''}${last.text}';
    return Pressable(
      onPressed: onPressed,
      selected: selected,
      semanticLabel: '${chat.person.name}. $preview${unread ? '. Unread' : ''}',
      builder: (context, states) => AnimatedFill(
        color: selected
            ? scheme.accent
            : states.contains(WidgetState.hovered)
            ? scheme.foreground.withValues(alpha: .05)
            : scheme.foreground.withValues(alpha: 0),
        borderRadius: theme.radii.lg,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              PersonAvatar(chat.person, size: 52, showOnline: true),
              const Gap.sm(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chat.person.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.small.copyWith(
                        color: scheme.foreground,
                        fontWeight: unread ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.caption.copyWith(
                        color: typing
                            ? scheme.tint
                            : unread
                            ? scheme.foreground
                            : null,
                        fontWeight: unread ? FontWeight.w700 : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.tint,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThreadTitle extends StatelessWidget {
  const _ThreadTitle(this.chat);

  final Chat chat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final person = chat.person;
    return Pressable(
      onPressed: () => openProfile(context, person),
      semanticLabel: person.name,
      builder: (context, states) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PersonAvatar(person, size: 36, showOnline: true),
          const Gap.sm(),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.small.copyWith(
                    color: theme.colorScheme.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  person.online
                      ? 'Active now'
                      : person.lastSeen == null
                      ? 'Offline'
                      : 'Active ${person.lastSeen} ago',
                  style: theme.textTheme.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A conversation: the messages, newest at the bottom, the other side
/// typing when they are, and the composer.
class Thread extends StatefulWidget {
  const Thread(this.chat, {this.showHeader = true, super.key});

  final Chat chat;

  /// Whether the thread draws its own header: a page with an app bar has
  /// one already.
  final bool showHeader;

  @override
  State<Thread> createState() => _ThreadState();
}

class _ThreadState extends State<Thread> {
  final _text = TextEditingController();
  final _focus = FocusNode(debugLabel: 'Message');
  late final SocialSession _session = context.social;

  @override
  void initState() {
    super.initState();
    _session.visibleChat = widget.chat.id;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _session.markChatRead(widget.chat),
    );
    _text.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    if (_session.visibleChat == widget.chat.id) _session.visibleChat = null;
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send([String? quick]) {
    final text = (quick ?? _text.text).trim();
    if (text.isEmpty) return;
    _session.send(widget.chat, text);
    _text.clear();
    if (quick == null) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chat = widget.chat;
    return ListenableBuilder(
      listenable: _session,
      builder: (context, _) {
        final messages = _session.messagesOf(chat);
        final typing = _session.isTyping(chat);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.showHeader) ...[
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: theme.gap(GapSize.md),
                  vertical: theme.gap(GapSize.sm),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _ThreadTitle(chat),
                      ),
                    ),
                    IconButton.ghost(
                      icon: PhosphorIcon(
                        PhosphorIconsFill.phone,
                        color: scheme.tint,
                      ),
                      semanticLabel: 'Voice call',
                      onPressed: () => _call(context, chat, video: false),
                    ),
                    IconButton.ghost(
                      icon: PhosphorIcon(
                        PhosphorIconsFill.videoCamera,
                        color: scheme.tint,
                      ),
                      semanticLabel: 'Video call',
                      onPressed: () => _call(context, chat, video: true),
                    ),
                    IconButton.ghost(
                      icon: PhosphorIcon(
                        PhosphorIconsFill.info,
                        color: scheme.tint,
                      ),
                      semanticLabel: 'Conversation details',
                      onPressed: () => openProfile(context, chat.person),
                    ),
                  ],
                ),
              ),
              const Divider(margin: EdgeInsets.zero),
            ],
            Expanded(
              child: messages.isEmpty && !typing
                  ? _EmptyThread(chat, onQuick: _send)
                  : ChatList<ChatMessage>(
                      messages: messages,
                      idOf: (message) => message.id,
                      sameGroup: (previous, next) =>
                          previous.fromMe == next.fromMe && next.time == null,
                      directionOf: (message) => message.fromMe
                          ? ChatBubbleDirection.outgoing
                          : ChatBubbleDirection.incoming,
                      padding: EdgeInsets.all(theme.gap(GapSize.md)),
                      footer: typing
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  PersonAvatar(chat.person, size: 28),
                                  const Gap.sm(),
                                  const ChatBubble(
                                    direction: ChatBubbleDirection.incoming,
                                    child: TypingIndicator(),
                                  ),
                                ],
                              ),
                            )
                          : null,
                      itemBuilder: (context, item) =>
                          _Message(chat: chat, item: item),
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                theme.gap(GapSize.md),
                theme.gap(GapSize.sm),
                theme.gap(GapSize.md),
                theme.gap(GapSize.md) +
                    (widget.showHeader
                        ? 0
                        : MediaQuery.paddingOf(context).bottom),
              ),
              child: Row(
                children: [
                  IconButton.ghost(
                    icon: PhosphorIcon(
                      PhosphorIconsFill.plusCircle,
                      color: scheme.tint,
                    ),
                    semanticLabel: 'More',
                    onPressed: () => _send('📷 Sent a photo'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _text,
                      focusNode: _focus,
                      placeholder: const Text('Aa'),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: UnaDecoration(
                        color: scheme.muted,
                        border: UnaBorder.all(
                          color: const Color(0x00000000),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                  const Gap.xs(),
                  ContentSwitch(
                    value: _text.text.trim().isEmpty,
                    direction: 0,
                    child: _text.text.trim().isEmpty
                        ? IconButton.ghost(
                            key: const ValueKey('like'),
                            icon: PhosphorIcon(
                              PhosphorIconsFill.thumbsUp,
                              color: scheme.tint,
                            ),
                            semanticLabel: 'Send a like',
                            onPressed: () => _send('👍'),
                          )
                        : IconButton.ghost(
                            key: const ValueKey('send'),
                            icon: PhosphorIcon(
                              PhosphorIconsFill.paperPlaneRight,
                              color: scheme.tint,
                            ),
                            semanticLabel: 'Send',
                            onPressed: _send,
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.chat, required this.item});

  final Chat chat;
  final ChatListItem<ChatMessage> item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final message = item.message;
    final mine = message.fromMe;
    final bubble = ChatBubble(
      direction: mine
          ? ChatBubbleDirection.outgoing
          : ChatBubbleDirection.incoming,
      showTail: item.isLastInGroup,
      color: mine ? scheme.primary : null,
      foregroundColor: mine ? scheme.primaryForeground : null,
      child: Text(message.text),
    );
    return Column(
      crossAxisAlignment: mine
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.time != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(message.time!, style: theme.textTheme.caption),
            ),
          ),
        if (mine)
          bubble
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                width: 28,
                child: item.isLastInGroup
                    ? PersonAvatar(chat.person, size: 28)
                    : null,
              ),
              const Gap.sm(),
              Flexible(child: bubble),
            ],
          ),
      ],
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread(this.chat, {required this.onQuick});

  final Chat chat;
  final ValueChanged<String> onQuick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(theme.gap(GapSize.lg)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PersonAvatar(chat.person, size: 88),
            const Gap.md(),
            Text(
              chat.person.name,
              style: theme.textTheme.h4.copyWith(
                color: theme.colorScheme.foreground,
              ),
            ),
            Text(
              'You are friends on Una Social · ${chat.person.city}',
              textAlign: TextAlign.center,
              style: theme.textTheme.muted,
            ),
            const Gap.lg(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final quick in ['Hey! 👋', 'How are you?', 'Coffee soon?'])
                  Chip(onPressed: () => onQuick(quick), label: Text(quick)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
