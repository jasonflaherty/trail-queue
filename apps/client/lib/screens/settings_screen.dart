import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final designKit = ref.watch(designKitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'Appearance'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                        value: ThemeMode.light,
                        label: Text('Light'),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.dark,
                        label: Text('Dark'),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemeMode.system,
                        label: Text('Auto'),
                        icon: Icon(Icons.brightness_auto_outlined),
                      ),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (selection) {
                      ref.read(themeModeProvider.notifier).state =
                          selection.first;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      _themeModeLabel(themeMode),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  if (kIsWeb) ...[
                    const SizedBox(height: 16),
                    Text('Design style',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    SegmentedButton<DesignKit>(
                      segments: const [
                        ButtonSegment(
                          value: DesignKit.material3,
                          label: Text('Material'),
                          icon: Icon(Icons.android),
                        ),
                        ButtonSegment(
                          value: DesignKit.ios26,
                          label: Text('iOS'),
                          icon: Icon(Icons.apple),
                        ),
                      ],
                      selected: {_effectiveKit(designKit)},
                      onSelectionChanged: (selection) {
                        ref.read(designKitProvider.notifier).state =
                            selection.first;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _effectiveKit(designKit) == DesignKit.ios26
                            ? 'iOS 26 look: capsule buttons and glass surfaces'
                            : 'Material 3 look: Android design components',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Data'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.download_for_offline_outlined),
                  title: const Text('Offline & Sync'),
                  subtitle: const Text(
                      'Download work areas and manage queued changes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/offline'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  subtitle: const Text('View your notification inbox'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'About'),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Version'),
                  trailing: Text('0.1.0'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Source code'),
                  subtitle: const Text('github.com/jasonflaherty/trail-queue'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => launchUrl(
                    Uri.parse('https://github.com/jasonflaherty/trail-queue'),
                    mode: LaunchMode.externalApplication,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Open source licenses'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showLicensePage(
                    context: context,
                    applicationName: 'Trail Queue',
                    applicationVersion: '0.1.0',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          TqOutlineButton(
            label: 'Sign Out',
            icon: Icons.logout,
            onPressed: () async {
              await ref.read(servicesProvider).auth.signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }

  /// The kit actually rendered: explicit choice, or the platform default
  /// (Chrome on macOS auto-selects the iOS look, elsewhere Material 3).
  DesignKit _effectiveKit(DesignKit kit) {
    if (kit != DesignKit.auto) return kit;
    final platform = defaultTargetPlatform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS
        ? DesignKit.ios26
        : DesignKit.material3;
  }

  String _themeModeLabel(ThemeMode mode) => switch (mode) {
        ThemeMode.dark => 'Dark theme enabled',
        ThemeMode.light => 'Light theme enabled',
        ThemeMode.system => 'Follow system setting',
      };
}
