import 'package:disco/disco.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:una/una.dart';

/// The places the shell can show. The order is the shell's destination
/// order, so an index is a value.
enum Destination {
  home,
  friends,
  groups,
  marketplace,
  events,
  notifications,
  messages,

  /// A phone's last tab: your profile, shortcuts and settings. A desktop
  /// has these in the account menu.
  menu,
}

/// The destination the shell shows.
final destinationProvider = Provider((_) => Signal(Destination.home));

extension SocialNavigation on BuildContext {
  /// Shows [destination] in the shell.
  void goTo(Destination destination) =>
      destinationProvider.of(this).value = destination;

  /// Closes the page this context is on, then shows [destination]: from a
  /// pushed page, [goTo] would switch the shell underneath it.
  void leaveTo(Destination destination) {
    final navigator = Navigator.of(this);
    final signal = destinationProvider.of(this);
    navigator.popUntil((route) => route.isFirst);
    signal.value = destination;
  }

  /// Pushes a page over the shell's bars.
  Future<T?> pushPage<T>(WidgetBuilder builder) =>
      Navigator.of(this).push(UnaPageRoute<T>(builder: builder));
}
