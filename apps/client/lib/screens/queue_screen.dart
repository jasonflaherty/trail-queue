import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';
import '../widgets/app_overflow_menu.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(myQueueProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Queue'),
        actions: const [AppOverflowMenu()],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myQueueProvider),
        child: queueAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: EmptyState(
                  title: 'Could not load queue',
                  message: error.toString(),
                ),
              ),
            ],
          ),
          data: (issues) {
            if (issues.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: EmptyState(
                      title: 'Your queue is empty',
                      message: 'Add issues from Home or issue details.',
                      action: TqPrimaryButton(
                        label: 'Browse Work Near You',
                        onPressed: () => context.go('/home'),
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: issues.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final issue = issues[index];
                return IssueCard(
                  issue: issue,
                  onTap: () => context.push('/issues/${issue.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
