import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class KanbanScreen extends ConsumerWidget {
  const KanbanScreen({super.key});

  static const _columns = [
    IssueStatus.open,
    IssueStatus.assigned,
    IssueStatus.scheduled,
    IssueStatus.inProgress,
    IssueStatus.needsVerification,
    IssueStatus.closed,
  ];

  IssueStatus? _nextStatus(IssueStatus current) {
    final index = _columns.indexOf(current);
    if (index < 0 || index >= _columns.length - 1) return null;
    return _columns[index + 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issuesAsync = ref.watch(issuesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kanban Board')),
      body: issuesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            EmptyState(title: 'Could not load issues', message: error.toString()),
        data: (issues) {
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(16),
            children: _columns.map((status) {
              final columnIssues =
                  issues.where((issue) => issue.status == status).toList();
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      status.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${columnIssues.length} issues',
                      style: const TextStyle(color: TqColors.slate),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.separated(
                        itemCount: columnIssues.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final issue = columnIssues[index];
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () async {
                                final next = _nextStatus(status);
                                if (next == null) return;
                                await ref
                                    .read(servicesProvider)
                                    .issues
                                    .updateStatus(issue.id, next);
                                refreshIssueData(ref);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PriorityBadge(
                                      priority: issue.priority,
                                      compact: true,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      issue.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (issue.trailName != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        issue.trailName!,
                                        style: const TextStyle(
                                          color: TqColors.slate,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to advance',
                                      style: TextStyle(
                                        color: TqColors.forestGreen
                                            .withValues(alpha: 0.8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
