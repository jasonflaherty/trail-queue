import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final orgsAsync = ref.watch(organizationsProvider);
    final jobsAsync = ref.watch(importJobsProvider);
    final stats = DemoData.stats;

    if (user == null || (!user.isAdmin && !user.canImport)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin')),
        body: const EmptyState(
          title: 'Access denied',
          message: 'Admin or land manager role required.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Signed in as ${user.displayName} (${user.primaryRole.label}). '
                'Use this dashboard to approve organizations and monitor imports.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Dashboard'),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              StatTile(
                label: 'Open issues',
                value: '${stats.openIssues}',
                icon: Icons.report_outlined,
              ),
              StatTile(
                label: 'Volunteer hours',
                value: '${stats.volunteerHours.round()}',
                icon: Icons.schedule,
              ),
              StatTile(
                label: 'Active crews',
                value: '${stats.activeCrews}',
                icon: Icons.groups_outlined,
              ),
              StatTile(
                label: 'Trails maintained',
                value: '${stats.trailsMaintained}',
                icon: Icons.terrain,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Organization approvals'),
          orgsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Could not load organizations'),
            data: (orgs) {
              final pending = orgs.where((org) => !org.approved).toList();
              if (pending.isEmpty) {
                return const Text('All organizations approved.');
              }
              return Column(
                children: pending
                    .map(
                      (org) => Card(
                        child: ListTile(
                          title: Text(org.name),
                          subtitle: Text(org.description ?? ''),
                          trailing: FilledButton(
                            onPressed: () async {
                              await ref
                                  .read(servicesProvider)
                                  .organizations
                                  .approve(org.id);
                              ref.invalidate(organizationsProvider);
                            },
                            child: const Text('Approve'),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Import jobs'),
          jobsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Could not load import jobs'),
            data: (jobs) {
              if (jobs.isEmpty) {
                return const Text('No import jobs yet.');
              }
              final dateFormat = DateFormat('MMM d • h:mm a');
              return Column(
                children: jobs
                    .map(
                      (job) => Card(
                        child: ListTile(
                          title: Text(job.source.label),
                          subtitle: Text(
                            '${job.status.name} • ${job.trailCount} trails • '
                            '${job.createdAt != null ? dateFormat.format(job.createdAt!) : 'Pending'}',
                          ),
                          trailing: Icon(
                            job.status == ImportJobStatus.completed
                                ? Icons.check_circle
                                : Icons.hourglass_top,
                            color: TqColors.forestGreen,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Duplicate cleanup'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.content_copy, color: TqColors.slate),
              title: const Text('Review duplicate issues'),
              subtitle: const Text('AI-assisted duplicate detection coming soon.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Duplicate cleanup stub')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
