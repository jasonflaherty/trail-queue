import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class OrganizationsScreen extends ConsumerWidget {
  const OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orgsAsync = ref.watch(organizationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Organizations')),
      body: orgsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(title: 'Could not load orgs', message: '$e'),
        data: (orgs) {
          final approved = orgs.where((o) => o.approved).toList();
          if (approved.isEmpty) {
            return const EmptyState(
              title: 'No organizations yet',
              message: 'Trail associations and nonprofits will appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Find trail builders, nonprofits, associations, and agencies '
                'accepting help from the public.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TqColors.slate,
                    ),
              ),
              const SizedBox(height: 16),
              ...approved.map(
                (org) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OrgCard(
                    org: org,
                    onTap: () => context.push('/organizations/${org.id}'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OrgCard extends StatelessWidget {
  const _OrgCard({required this.org, this.onTap});

  final Organization org;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      org.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TqColors.forestGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      org.kind.label,
                      style: const TextStyle(
                        color: TqColors.forestGreen,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (org.region != null) ...[
                const SizedBox(height: 4),
                Text(org.region!, style: const TextStyle(color: TqColors.slate)),
              ],
              if (org.description != null) ...[
                const SizedBox(height: 8),
                Text(
                  org.description!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  EffortChip(
                    label: '${org.openWorkCount} open jobs',
                    icon: Icons.handyman_outlined,
                  ),
                  EffortChip(
                    label: '${org.memberCount} members',
                    icon: Icons.groups_outlined,
                  ),
                  if (org.acceptingVolunteers)
                    const EffortChip(
                      label: 'Accepting volunteers',
                      icon: Icons.volunteer_activism_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
