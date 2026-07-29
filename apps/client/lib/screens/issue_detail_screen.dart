import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';

class IssueDetailScreen extends ConsumerWidget {
  const IssueDetailScreen({super.key, required this.issueId});

  final String issueId;

  Future<void> _copyGps(BuildContext context, GeoPoint location) async {
    await Clipboard.setData(
      ClipboardData(text: location.display),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS coordinates copied')),
      );
    }
  }

  Future<void> _shareIssue(TrailIssue issue) async {
    await Share.share(
      '${issue.title}\n${issue.trailName ?? ''}\n${issue.location.display}',
      subject: issue.title,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issueFuture = ref.watch(servicesProvider).issues.getById(issueId);

    return FutureBuilder<TrailIssue?>(
      future: issueFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final issue = snapshot.data;
        if (issue == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(title: 'Issue not found'),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(issue.issueIdLabel),
            leading: BackButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            actions: [
              IconButton(
                onPressed: () => _shareIssue(issue),
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share issue',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    if (issue.photoUrls.isNotEmpty)
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          issue.photoUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: TqColors.sand,
                            child: const Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              PriorityBadge(priority: issue.priority),
                              const SizedBox(width: 8),
                              Text(
                                issue.issueIdLabel,
                                style: const TextStyle(
                                  color: TqColors.slate,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            issue.title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            [
                              if (issue.trailName != null) issue.trailName!,
                              if (issue.distanceMiles != null)
                                '${issue.distanceMiles!.toStringAsFixed(1)} mi away',
                            ].join(' • '),
                            style: const TextStyle(color: TqColors.slate),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              EffortChip(
                                label: issue.type.label,
                                icon: Icons.category_outlined,
                              ),
                              for (final extra in issue.secondaryTypes)
                                EffortChip(
                                  label: '+ ${extra.label}',
                                  icon: Icons.add_circle_outline,
                                ),
                              EffortChip(label: issue.timeLabel),
                              EffortChip(
                                label: issue.crewSizeLabel,
                                icon: Icons.groups_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (issue.description != null) ...[
                            Text(
                              issue.description!,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 20),
                          ],
                          _DetailRow(
                            label: 'Reported by',
                            value: issue.reportedByName ?? 'Unknown',
                          ),
                          if (issue.agency != null)
                            _DetailRow(label: 'Agency', value: issue.agency!),
                          if (issue.trailUses.isNotEmpty)
                            _DetailRow(
                              label: 'Trail type',
                              value: issue.trailUses.join(', '),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _DetailRow(
                                  label: 'GPS',
                                  value: issue.location.display,
                                ),
                              ),
                              IconButton(
                                onPressed: () => _copyGps(context, issue.location),
                                icon: const Icon(Icons.copy_outlined),
                                tooltip: 'Copy coordinates',
                              ),
                              IconButton(
                                onPressed: () {
                                  final uri = Uri.parse(
                                    'https://maps.google.com/?q=${issue.location.latitude},${issue.location.longitude}',
                                  );
                                  launchUrl(uri, mode: LaunchMode.externalApplication);
                                },
                                icon: const Icon(Icons.map_outlined),
                                tooltip: 'Open in maps',
                              ),
                            ],
                          ),
                          if (issue.photoUrls.length > 1) ...[
                            const SizedBox(height: 20),
                            const SectionHeader(title: 'Photos'),
                            const SizedBox(height: 8),
                            PhotoGallery(urls: issue.photoUrls),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: TqOutlineButton(
                          label: issue.inMyQueue ? 'In My Queue' : 'Add to My Queue',
                          icon: Icons.playlist_add,
                          onPressed: issue.inMyQueue
                              ? null
                              : () async {
                                  await ref
                                      .read(servicesProvider)
                                      .issues
                                      .addToQueue(issue.id);
                                  refreshIssueData(ref);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Added to your queue'),
                                      ),
                                    );
                                  }
                                },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TqPrimaryButton(
                          label: 'I Can Help',
                          icon: Icons.volunteer_activism_outlined,
                          onPressed: () async {
                            await ref
                                .read(servicesProvider)
                                .issues
                                .acceptIssue(issue.id);
                            refreshIssueData(ref);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Issue accepted')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: TqColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
