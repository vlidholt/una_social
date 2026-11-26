import 'package:flutter/widgets.dart';
import 'package:flutter_solidart/flutter_solidart.dart';
import 'package:una/una.dart';
import 'package:una_social/app_state.dart';

enum _Audience { everyone, friends, onlyMe }

/// Settings & privacy: how the app looks, what it tells you, and who sees
/// your posts.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _push = true;
  bool _email = false;
  bool _birthdays = true;
  bool _activeStatus = true;
  _Audience _audience = _Audience.friends;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings & privacy')),
      body: PageContainer(
        scrollable: true,
        maxWidth: 680,
        child: SignalBuilder(
          builder: (context, _) {
            final mode = themeModeProvider.of(context);
            final glass = liquidGlassProvider.of(context);
            final scale = textScaleProvider.of(context);
            return UnaColumn(
              gap: GapSize.lg,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ListSection(
                  header: const Text('Appearance'),
                  children: [
                    ListTile(
                      title: const Text('Theme'),
                      trailing: SegmentedControl<ThemeMode>(
                        value: mode.value,
                        onChanged: (value) => mode.value = value,
                        segments: const [
                          Segment(value: ThemeMode.light, label: Text('Light')),
                          Segment(value: ThemeMode.dark, label: Text('Dark')),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('Liquid Glass'),
                      subtitle: const Text('Automatic on iPhone, iPad and Mac'),
                      trailing: SegmentedControl<LiquidGlassMode>(
                        value: glass.value,
                        onChanged: (value) => glass.value = value,
                        segments: const [
                          Segment(
                            value: LiquidGlassMode.auto,
                            label: Text('Auto'),
                          ),
                          Segment(
                            value: LiquidGlassMode.always,
                            label: Text('On'),
                          ),
                          Segment(
                            value: LiquidGlassMode.never,
                            label: Text('Off'),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      title: const Text('Text size'),
                      subtitle: Slider(
                        value: scale.value,
                        min: .85,
                        max: 1.3,
                        divisions: 9,
                        onChanged: (value) => scale.value = value,
                      ),
                    ),
                  ],
                ),
                ListSection(
                  header: const Text('Notifications'),
                  children: [
                    SwitchListTile(
                      title: const Text('Push notifications'),
                      value: _push,
                      onChanged: (value) => setState(() => _push = value),
                    ),
                    SwitchListTile(
                      title: const Text('Email digest'),
                      subtitle: const Text(
                        'A weekly summary of what you missed',
                      ),
                      value: _email,
                      onChanged: (value) => setState(() => _email = value),
                    ),
                    SwitchListTile(
                      title: const Text('Birthdays'),
                      value: _birthdays,
                      onChanged: (value) => setState(() => _birthdays = value),
                    ),
                  ],
                ),
                ListSection(
                  header: const Text('Privacy'),
                  footer: const Text(
                    'Who can see your future posts. Posts you have shared keep their audience.',
                  ),
                  children: [
                    ListTile(
                      title: const Text('Default audience'),
                      trailing: Select<_Audience>(
                        value: _audience,
                        onChanged: (value) =>
                            setState(() => _audience = value!),
                        options: const [
                          SelectOption(
                            value: _Audience.everyone,
                            child: Text('Everyone'),
                          ),
                          SelectOption(
                            value: _Audience.friends,
                            child: Text('Friends'),
                          ),
                          SelectOption(
                            value: _Audience.onlyMe,
                            child: Text('Only me'),
                          ),
                        ],
                        selectedOptionBuilder: (context, value) =>
                            Text(switch (value) {
                              _Audience.everyone => 'Everyone',
                              _Audience.friends => 'Friends',
                              _Audience.onlyMe => 'Only me',
                            }),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Show when you are active'),
                      value: _activeStatus,
                      onChanged: (value) =>
                          setState(() => _activeStatus = value),
                    ),
                  ],
                ),
                const Gap.md(),
              ],
            );
          },
        ),
      ),
    );
  }
}
