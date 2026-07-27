import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';
import '../widgets/greeting.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final issuesAsync = ref.watch(issuesProvider);
    final notificationsAsync = ref.watch(notificationsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadCount = notificationsAsync.maybeWhen(
      data: (items) => items.where((n) => !n.read).length,
      orElse: () => 0,
    );

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => refreshIssueData(ref),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${greetingForTimeOfDay()}, ${user?.displayName ?? 'Volunteer'}',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Let's keep trails open",
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: TqColors.slate,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => context.push('/notifications'),
                        tooltip: unreadCount > 0
                            ? 'Notifications, $unreadCount unread'
                            : 'Notifications',
                        icon: Badge(
                          isLabelVisible: unreadCount > 0,
                          label: Text('$unreadCount'),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TqPrimaryButton(
                        label: 'Report an Issue',
                        icon: Icons.add_a_photo_outlined,
                        onPressed: () => context.push('/report'),
                      ),
                      const SizedBox(height: 12),
                      TqOutlineButton(
                        label: 'Find Organizations',
                        icon: Icons.handshake_outlined,
                        onPressed: () => context.push('/organizations'),
                      ),
                      if (isDark) ...[
                        const SizedBox(height: 12),
                        TqOutlineButton(
                          label: 'Find Work',
                          icon: Icons.search,
                          onPressed: () => context.go('/map'),
                        ),
                      ],
                      const SizedBox(height: 28),
                      SectionHeader(
                        title: 'Partner organizations',
                        actionLabel: 'See all',
                        onAction: () => context.push('/organizations'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nonprofits, associations, and trail builders mobilizing help.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: TqColors.slate,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Consumer(
                        builder: (context, ref, _) {
                          final orgs = ref.watch(organizationsProvider);
                          return orgs.maybeWhen(
                            data: (list) {
                              final shown =
                                  list.where((o) => o.approved).take(3).toList();
                              return Column(
                                children: shown
                                    .map(
                                      (org) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(
                                          Icons.apartment_outlined,
                                          color: TqColors.forestGreen,
                                        ),
                                        title: Text(org.name),
                                        subtitle: Text(
                                          '${org.kind.label} • ${org.openWorkCount} open jobs',
                                        ),
                                        trailing: const Icon(Icons.chevron_right),
                                        onTap: () => context
                                            .push('/organizations/${org.id}'),
                                      ),
                                    )
                                    .toList(),
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(title: 'Work Near You'),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              issuesAsync.when(
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    title: 'Could not load issues',
                    message: error.toString(),
                    action: TqPrimaryButton(
                      label: 'Retry',
                      onPressed: () => ref.invalidate(issuesProvider),
                    ),
                  ),
                ),
                data: (issues) {
                  if (issues.isEmpty) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyState(
                        title: 'No issues nearby',
                        message: 'Check back later or expand your search on the map.',
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: issues.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final issue = issues[index];
                        return IssueCard(
                          issue: issue,
                          onTap: () => context.push('/issues/${issue.id}'),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
