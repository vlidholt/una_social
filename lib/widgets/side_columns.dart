import 'package:flutter/widgets.dart';
import 'package:una/una.dart';
import 'package:una_social/data.dart';
import 'package:una_social/navigation.dart';
import 'package:una_social/screens/groups_screen.dart';
import 'package:una_social/screens/menu_screen.dart';
import 'package:una_social/screens/profile_screen.dart';
import 'package:una_social/session.dart';
import 'package:una_social/widgets/pieces.dart';

/// Opens what a shortcut names: a destination, or a page.
void openShortcut(BuildContext context, Shortcut shortcut) {
  switch (shortcut.destination) {
    case 'saved':
      openSaved(context);
    case 'memories':
      openMemories(context);
    default:
      context.goTo(Destination.values.byName(shortcut.destination));
  }
}

/// A row in a side column: something round at the start and a label,
/// with a soft fill under the pointer.
class SideRow extends StatelessWidget {
  const SideRow({
    required this.leading,
    required this.label,
    required this.onPressed,
    this.trailing,
    this.subtitle,
    super.key,
  });

  final Widget leading;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Pressable(
      onPressed: onPressed,
      semanticLabel: label,
      builder: (context, states) => FocusRing(
        visible: states.contains(WidgetState.focused),
        borderRadius: theme.radii.lg,
        child: AnimatedFill(
          color: states.contains(WidgetState.hovered)
              ? scheme.foreground.withValues(alpha: .05)
              : scheme.foreground.withValues(alpha: 0),
          borderRadius: theme.radii.lg,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                leading,
                const Gap.sm(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.small.copyWith(
                          color: scheme.foreground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.caption,
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A shortcut's icon on a tile of its colour.
class ShortcutIcon extends StatelessWidget {
  const ShortcutIcon(this.shortcut, {this.size = 36, super.key});

  final Shortcut shortcut;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(shortcut.color, const Color(0xFFFFFFFF), .2)!,
            shortcut.color,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: PhosphorIcon(
        shortcut.icon,
        size: size * .52,
        color: const Color(0xFFFFFFFF),
      ),
    );
  }
}

/// The desktop home's start column: you, the shortcuts and your groups.
class ShortcutsColumn extends StatelessWidget {
  const ShortcutsColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: context.social,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SideRow(
            leading: PersonAvatar(People.me, size: 36),
            label: People.me.name,
            onPressed: () => openProfile(context, People.me),
          ),
          for (final shortcut in shortcuts)
            SideRow(
              leading: ShortcutIcon(shortcut),
              label: shortcut.label,
              onPressed: () => openShortcut(context, shortcut),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: const Divider(margin: EdgeInsets.zero),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Text(
              'Your groups',
              style: theme.textTheme.small.copyWith(
                color: theme.colorScheme.mutedForeground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final group in context.social.myGroups)
            SideRow(
              leading: Photo(
                group.cover,
                height: 36,
                borderRadius: theme.radii.md,
              ).sized(36),
              label: group.name,
              subtitle: '${group.postsPerDay} new posts today',
              onPressed: () => openGroup(context, group),
            ),
          const Gap.lg(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Privacy · Terms · Advertising · Cookies · Una Social © 2026',
              style: theme.textTheme.caption,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget sized(double side) => SizedBox.square(dimension: side, child: this);
}

/// The desktop home's end column: birthdays, then your contacts with who
/// is online, then group conversations.
class ContactsColumn extends StatelessWidget {
  const ContactsColumn({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final session = context.social;
    final birthdays = Birthdays.today;

    void chat(Person person) {
      session.openChatWith(person);
      context.goTo(Destination.messages);
    }

    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final friends = session.friends;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              style: CardTheme(padding: EdgeInsets.all(theme.gap(GapSize.md))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _GiftIcon(),
                  const Gap.sm(),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: birthdays.first.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: birthdays.last.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const TextSpan(text: ' have birthdays today.'),
                        ],
                      ),
                      style: theme.textTheme.small.copyWith(
                        color: scheme.foreground,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap.lg(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Contacts',
                      style: theme.textTheme.small.copyWith(
                        color: scheme.mutedForeground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton.ghost(
                    size: ButtonSize.sm,
                    icon: const PhosphorIcon(PhosphorIconsRegular.videoCamera),
                    semanticLabel: 'New room',
                    onPressed: () => showSocialToast(
                      context,
                      'Room created',
                      description: 'Share the link to invite friends.',
                      variant: ToastVariant.success,
                    ),
                  ),
                  IconButton.ghost(
                    size: ButtonSize.sm,
                    icon: const PhosphorIcon(
                      PhosphorIconsRegular.magnifyingGlass,
                    ),
                    semanticLabel: 'Search contacts',
                    onPressed: () => context.goTo(Destination.messages),
                  ),
                ],
              ),
            ),
            for (final person in friends)
              SideRow(
                leading: PersonAvatar(person, size: 36, showOnline: true),
                label: person.name,
                trailing: person.online || person.lastSeen == null
                    ? null
                    : Text(person.lastSeen!, style: theme.textTheme.caption),
                onPressed: () => chat(person),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: const Divider(margin: EdgeInsets.zero),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Text(
                'Group conversations',
                style: theme.textTheme.small.copyWith(
                  color: scheme.mutedForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SideRow(
              leading: SizedBox(
                width: 36,
                height: 36,
                child: AvatarGroup(
                  size: 24,
                  children: [
                    Image.asset(People.jonas.photo, fit: BoxFit.cover),
                    Image.asset(People.mei.photo, fit: BoxFit.cover),
                  ],
                ),
              ),
              label: 'Sunrise hikers',
              subtitle: 'Jonas: 4:30 at the hut?',
              onPressed: () => chat(People.jonas),
            ),
            SideRow(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.muted,
                ),
                child: PhosphorIcon(
                  PhosphorIconsBold.plus,
                  size: 16,
                  color: scheme.foreground,
                ),
              ),
              label: 'Create new group',
              onPressed: () => context.goTo(Destination.groups),
            ),
          ],
        );
      },
    );
  }
}

class _GiftIcon extends StatelessWidget {
  const _GiftIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFF472B6), Color(0xFFEC4899)],
        ),
      ),
      child: const PhosphorIcon(
        PhosphorIconsFill.gift,
        size: 18,
        color: Color(0xFFFFFFFF),
      ),
    );
  }
}
