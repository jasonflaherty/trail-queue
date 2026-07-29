import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trail_queue_api/trail_queue_api.dart';
import 'package:trail_queue_map/trail_queue_map.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class OfflineScreen extends ConsumerStatefulWidget {
  const OfflineScreen({super.key});

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen> {
  bool _downloading = false;
  bool _syncing = false;

  Future<void> _downloadWorkArea() async {
    setState(() => _downloading = true);
    try {
      final location = await ref.read(userLocationProvider.future);
      final area = await ref.read(servicesProvider).sync.downloadWorkArea(
            label: 'Field work area',
            latitude: location.latitude,
            longitude: location.longitude,
            radiusMiles: 15,
          );
      // Mark map tile region for offline intent.
      await OfflineTileCache.instance.put(
        'work_area',
        '${area.centerLat},${area.centerLng},${area.radiusMiles}',
      );
      ref.invalidate(workAreaProvider);
      ref.invalidate(pendingMutationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Downloaded ${area.issueCount} issues, ${area.trailCount} trails, '
              '${area.assetCount} assets for offline use',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _downloadState(UsStateRegion state) async {
    setState(() => _downloading = true);
    try {
      final area = await ref.read(servicesProvider).sync.downloadWorkArea(
            label: state.label,
            latitude: state.latitude,
            longitude: state.longitude,
            radiusMiles: state.radiusMiles,
          );
      await OfflineTileCache.instance.put(
        'state_${state.code}',
        '${area.centerLat},${area.centerLng},${area.radiusMiles}',
      );
      ref.invalidate(workAreaProvider);
      ref.invalidate(pendingMutationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Downloaded ${state.name}: ${area.issueCount} issues, '
              '${area.trailCount} trails (~${state.radiusMiles.round()} mi radius)',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _pickStateRegion() async {
    final selected = await showModalBottomSheet<UsStateRegion>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Text(
                    'Download a state region',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Caches issues, trails, and assets near the state center. '
                    'Western trail states are listed first.',
                    style: TextStyle(color: TqColors.slate),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: controller,
                    itemCount: UsStateRegions.prioritized.length,
                    itemBuilder: (context, index) {
                      final state = UsStateRegions.prioritized[index];
                      final isPriority =
                          UsStateRegions.trailPriorityCodes.contains(state.code);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPriority
                              ? TqColors.forestGreen.withValues(alpha: 0.15)
                              : TqColors.sand,
                          child: Text(
                            state.code,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: isPriority
                                  ? TqColors.forestGreen
                                  : TqColors.slate,
                            ),
                          ),
                        ),
                        title: Text(state.name),
                        subtitle: Text(
                          '~${state.radiusMiles.round()} mi radius around state center',
                        ),
                        trailing: const Icon(Icons.download_outlined),
                        onTap: () => Navigator.pop(context, state),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    if (selected != null) await _downloadState(selected);
  }

  Future<void> _sync() async {
    setState(() => _syncing = true);
    try {
      final result = await ref.read(servicesProvider).sync.syncNow();
      refreshIssueData(ref);
      ref.invalidate(pendingMutationsProvider);
      ref.invalidate(lastSyncedProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Sync complete')),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onlineAsync = ref.watch(isOnlineProvider);
    final online = onlineAsync.maybeWhen(
      data: (v) => v,
      orElse: () => ref.read(servicesProvider).offline.isOnline,
    );
    final pendingAsync = ref.watch(pendingMutationsProvider);
    final workAreaAsync = ref.watch(workAreaProvider);
    final lastSyncedAsync = ref.watch(lastSyncedProvider);
    final pendingCount = pendingAsync.maybeWhen(
      data: (list) => list.length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Offline & Sync')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: ListTile(
              leading: Icon(
                online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
                color: online ? TqColors.forestGreen : TqColors.priorityMedium,
              ),
              title: Text(online ? 'Online' : 'Offline'),
              subtitle: Text(
                online
                    ? 'Changes sync to the server when you save.'
                    : 'You can still report and claim work — sync when you reconnect.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Download work area',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cache nearby issues, trails, assets, and map region for field work without signal.',
                    style: TextStyle(color: TqColors.slate),
                  ),
                  const SizedBox(height: 12),
                  workAreaAsync.maybeWhen(
                    data: (area) {
                      if (area == null) {
                        return const Text(
                          'No work area downloaded yet.',
                          style: TextStyle(color: TqColors.slate, fontSize: 13),
                        );
                      }
                      return Text(
                        '${area.label}: ${area.issueCount} issues • '
                        '${area.trailCount} trails • ${area.assetCount} assets\n'
                        'Saved ${DateFormat.MMMd().add_jm().format(area.downloadedAt)}',
                        style: const TextStyle(fontSize: 13),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  TqPrimaryButton(
                    label: _downloading ? 'Downloading…' : 'Download nearby (15 mi)',
                    icon: Icons.download_outlined,
                    onPressed: _downloading ? null : _downloadWorkArea,
                  ),
                  const SizedBox(height: 8),
                  TqOutlineButton(
                    label: 'Download a state…',
                    icon: Icons.map_outlined,
                    onPressed: _downloading ? null : _pickStateRegion,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Popular trail states',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Quick download for common stewardship regions.',
                    style: TextStyle(color: TqColors.slate),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: UsStateRegions.prioritized
                        .where((s) =>
                            UsStateRegions.trailPriorityCodes.contains(s.code))
                        .take(8)
                        .map(
                          (state) => ActionChip(
                            avatar: Text(
                              state.code,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            label: Text(state.name),
                            onPressed:
                                _downloading ? null : () => _downloadState(state),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Pending sync',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: pendingCount > 0
                              ? TqColors.priorityMedium.withValues(alpha: 0.15)
                              : TqColors.forestGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: pendingCount > 0
                                ? TqColors.priorityMedium
                                : TqColors.forestGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  lastSyncedAsync.maybeWhen(
                    data: (at) => Text(
                      at == null
                          ? 'Not synced yet'
                          : 'Last synced ${DateFormat.MMMd().add_jm().format(at)}',
                      style: const TextStyle(color: TqColors.slate, fontSize: 13),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  pendingAsync.maybeWhen(
                    data: (mutations) {
                      if (mutations.isEmpty) {
                        return const Text(
                          'All changes are synced.',
                          style: TextStyle(color: TqColors.slate),
                        );
                      }
                      return Column(
                        children: mutations
                            .take(8)
                            .map(
                              (m) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                leading: Icon(
                                  _iconFor(m.kind),
                                  color: TqColors.forestGreen,
                                  size: 20,
                                ),
                                title: Text(_labelFor(m.kind)),
                                subtitle: Text(
                                  m.lastError ??
                                      DateFormat.jm().format(m.createdAt),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),
                  TqPrimaryButton(
                    label: _syncing ? 'Syncing…' : 'Sync now',
                    icon: Icons.sync,
                    onPressed: _syncing ? null : _sync,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const EmptyState(
            icon: Icons.wifi_off,
            title: 'Built for the trail',
            message:
                'Report issues, claim work, and browse your queue offline. '
                'When you get signal, Trail Queue pushes your changes and pulls updates.',
          ),
        ],
      ),
    );
  }

  IconData _iconFor(PendingMutationKind kind) => switch (kind) {
        PendingMutationKind.createIssue => Icons.add_a_photo_outlined,
        PendingMutationKind.updateStatus => Icons.flag_outlined,
        PendingMutationKind.addToQueue => Icons.playlist_add_check,
        PendingMutationKind.acceptIssue => Icons.handshake_outlined,
        PendingMutationKind.addComment => Icons.chat_bubble_outline,
      };

  String _labelFor(PendingMutationKind kind) => switch (kind) {
        PendingMutationKind.createIssue => 'New issue report',
        PendingMutationKind.updateStatus => 'Status update',
        PendingMutationKind.addToQueue => 'Added to My Queue',
        PendingMutationKind.acceptIssue => 'Accepted issue',
        PendingMutationKind.addComment => 'Comment',
      };
}
