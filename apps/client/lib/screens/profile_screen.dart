import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final orgsAsync = ref.watch(organizationsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final designKit = ref.watch(designKitProvider);

    if (user == null) {
      return const Scaffold(
        body: EmptyState(title: 'Not signed in'),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: TqColors.forestGreen.withValues(alpha: 0.15),
                    child: Text(
                      user.displayName.characters.first.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: TqColors.forestGreen,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (user.email != null)
                          Text(
                            user.email!,
                            style: const TextStyle(color: TqColors.slate),
                          ),
                        Text(
                          user.primaryRole.label,
                          style: const TextStyle(
                            color: TqColors.forestGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _ProfileSection(
            title: 'Skills',
            items: user.skills,
            emptyLabel: 'No skills listed',
          ),
          _ProfileSection(
            title: 'Certifications',
            items: user.certifications,
            emptyLabel: 'No certifications',
          ),
          _ProfileSection(
            title: 'Equipment',
            items: user.equipment,
            emptyLabel: 'No equipment listed',
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.schedule, color: TqColors.forestGreen),
              title: const Text('Volunteer hours'),
              trailing: Text(
                '${user.volunteerHours.toStringAsFixed(0)} hrs',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(
            title: 'Organizations',
            actionLabel: 'Browse',
            onAction: () => context.push('/organizations'),
          ),
          orgsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Could not load organizations'),
            data: (orgs) {
              final userOrgs = orgs
                  .where((org) => user.organizationIds.contains(org.id))
                  .toList();
              if (userOrgs.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Connect with a nonprofit, association, or trail builders group.',
                      style: TextStyle(color: TqColors.slate),
                    ),
                    const SizedBox(height: 8),
                    TqOutlineButton(
                      label: 'Find organizations',
                      icon: Icons.handshake_outlined,
                      onPressed: () => context.push('/organizations'),
                    ),
                  ],
                );
              }
              return Column(
                children: userOrgs
                    .map(
                      (org) => Card(
                        child: ListTile(
                          title: Text(org.name),
                          subtitle: Text(
                            '${org.kind.label} • ${org.openWorkCount} open jobs',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () =>
                              context.push('/organizations/${org.id}'),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Badges'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.badgeIds
                .map(
                  (badge) => Chip(
                    avatar: const Icon(Icons.military_tech, size: 18),
                    label: Text(badge.replaceAll('badge-', '').replaceAll('-', ' ')),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
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
          if (user.roles.contains(UserRole.crewLeader) ||
              user.isAdmin) ...[
            const SizedBox(height: 12),
            TqOutlineButton(
              label: 'Kanban Board',
              icon: Icons.view_kanban_outlined,
              onPressed: () => context.push('/kanban'),
            ),
          ],
          if (user.isAdmin || user.canImport) ...[
            const SizedBox(height: 12),
            TqOutlineButton(
              label: 'Admin Dashboard',
              icon: Icons.admin_panel_settings_outlined,
              onPressed: () => context.push('/admin'),
            ),
          ],
          const SizedBox(height: 12),
          TqOutlineButton(
            label: 'Offline & Sync',
            icon: Icons.download_for_offline_outlined,
            onPressed: () => context.push('/offline'),
          ),
          const SizedBox(height: 20),
          TqPrimaryButton(
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

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({
    required this.title,
    required this.items,
    required this.emptyLabel,
  });

  final String title;
  final List<String> items;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: title),
          const SizedBox(height: 8),
          if (items.isEmpty)
            Text(emptyLabel, style: const TextStyle(color: TqColors.slate))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((item) => Chip(label: Text(item))).toList(),
            ),
        ],
      ),
    );
  }
}
