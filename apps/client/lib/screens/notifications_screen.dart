import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final dateFormat = DateFormat('MMM d • h:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(notificationsProvider),
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.6,
                child: EmptyState(
                  title: 'Could not load notifications',
                  message: error.toString(),
                ),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.6,
                    child: const EmptyState(title: 'No notifications'),
                  ),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      _iconFor(item.kind),
                      color: item.read ? TqColors.slate : TqColors.forestGreen,
                    ),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        fontWeight:
                            item.read ? FontWeight.w500 : FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.body),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(item.createdAt),
                          style: const TextStyle(
                            color: TqColors.slate,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      await ref
                          .read(servicesProvider)
                          .notifications
                          .markRead(item.id);
                      ref.invalidate(notificationsProvider);
                      if (item.relatedId != null && context.mounted) {
                        if (item.kind.name.contains('issue')) {
                          context.push('/issues/${item.relatedId}');
                        } else if (item.kind.name.contains('crew')) {
                          context.push('/crews/${item.relatedId}');
                        }
                      }
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  IconData _iconFor(NotificationKind kind) => switch (kind) {
        NotificationKind.nearbyIssue => Icons.place_outlined,
        NotificationKind.crewInvitation => Icons.groups_outlined,
        NotificationKind.issueAssigned => Icons.assignment_outlined,
        NotificationKind.verificationRequested => Icons.verified_outlined,
        NotificationKind.workdayReminder => Icons.event_outlined,
      };
}
