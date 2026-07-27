import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class TrailDetailScreen extends ConsumerWidget {
  const TrailDetailScreen({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailsAsync = ref.watch(trailsProvider);
    final issuesAsync = ref.watch(issuesProvider);

    return trailsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(title: 'Could not load trail', message: error.toString()),
      ),
      data: (trails) {
        final trail = trails.cast<Trail?>().firstWhere(
              (t) => t!.id == trailId,
              orElse: () => null,
            );
        if (trail == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(title: 'Trail not found'),
          );
        }

        final relatedIssues = issuesAsync.maybeWhen(
          data: (issues) =>
              issues.where((issue) => issue.trailId == trail.id).toList(),
          orElse: () => const <TrailIssue>[],
        );
        final assets = DemoData.assets
            .where((a) => a.trailId == trail.id)
            .toList();

        return Scaffold(
          appBar: AppBar(title: Text(trail.name)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (trail.photoUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      trail.photoUrls.first,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (trail.agency != null)
                        _InfoRow(label: 'Agency', value: trail.agency!),
                      if (trail.lengthMiles != null)
                        _InfoRow(
                          label: 'Length',
                          value: '${trail.lengthMiles!.toStringAsFixed(1)} mi',
                        ),
                      if (trail.elevationGainFt != null)
                        _InfoRow(
                          label: 'Elevation',
                          value: '${trail.elevationGainFt!.round()} ft gain',
                        ),
                      _InfoRow(label: 'Difficulty', value: trail.difficulty.label),
                      if (trail.maintenanceScore != null)
                        _InfoRow(
                          label: 'Maintenance score',
                          value: '${trail.maintenanceScore!.round()}/100',
                        ),
                      if (trail.maintenanceGrade != null)
                        _InfoRow(
                          label: 'Grade',
                          value:
                              '${trail.maintenanceGrade!.emoji} ${trail.maintenanceGrade!.label}',
                        ),
                      _InfoRow(
                        label: 'Issues',
                        value:
                            '${trail.openIssueCount} open • ${trail.closedIssueCount} closed',
                      ),
                    ],
                  ),
                ),
              ),
              if (assets.isNotEmpty) ...[
                const SizedBox(height: 20),
                const SectionHeader(title: 'Assets'),
                const SizedBox(height: 8),
                ...assets.map(
                  (asset) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined,
                        color: TqColors.forestGreen),
                    title: Text(asset.name ?? asset.type.label),
                    subtitle: Text(asset.type.label),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const SectionHeader(title: 'Related Issues'),
              const SizedBox(height: 8),
              if (relatedIssues.isEmpty)
                const Text(
                  'No open issues on this trail.',
                  style: TextStyle(color: TqColors.slate),
                )
              else
                ...relatedIssues.map(
                  (issue) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: IssueCard(
                      issue: issue,
                      onTap: () => context.push('/issues/${issue.id}'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: TqColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
