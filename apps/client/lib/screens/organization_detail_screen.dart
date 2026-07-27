import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers.dart';

class OrganizationDetailScreen extends ConsumerStatefulWidget {
  const OrganizationDetailScreen({super.key, required this.organizationId});

  final String organizationId;

  @override
  ConsumerState<OrganizationDetailScreen> createState() =>
      _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState
    extends ConsumerState<OrganizationDetailScreen> {
  bool _joining = false;

  Future<void> _join() async {
    setState(() => _joining = true);
    try {
      await ref
          .read(servicesProvider)
          .auth
          .joinOrganization(widget.organizationId);
      ref.invalidate(organizationsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are connected. Watch for published work.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orgsAsync = ref.watch(organizationsProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    final issuesAsync = ref.watch(issuesProvider);

    return orgsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(title: 'Error', message: '$e'),
      ),
      data: (orgs) {
        final matches =
            orgs.where((o) => o.id == widget.organizationId).toList();
        if (matches.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(title: 'Organization not found'),
          );
        }
        final org = matches.first;

        final joined = user?.organizationIds.contains(org.id) ?? false;
        final work = issuesAsync.maybeWhen(
          data: (issues) => issues.take(5).toList(),
          orElse: () => const <TrailIssue>[],
        );
        final website = org.website;

        return Scaffold(
          appBar: AppBar(title: Text(org.name)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                org.kind.label,
                style: const TextStyle(
                  color: TqColors.forestGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (org.region != null) ...[
                const SizedBox(height: 4),
                Text(org.region!, style: const TextStyle(color: TqColors.slate)),
              ],
              const SizedBox(height: 12),
              if (org.description != null) Text(org.description!),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  EffortChip(
                    label: '${org.trailCount} trails',
                    icon: Icons.route_outlined,
                  ),
                  EffortChip(
                    label: '${org.memberCount} members',
                    icon: Icons.groups_outlined,
                  ),
                  EffortChip(
                    label: '${org.openWorkCount} open jobs',
                    icon: Icons.handyman_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (website != null)
                TqOutlineButton(
                  label: 'Visit website',
                  icon: Icons.open_in_new,
                  onPressed: () => launchUrl(Uri.parse(website)),
                ),
              const SizedBox(height: 12),
              if (org.acceptingVolunteers)
                TqPrimaryButton(
                  label: joined
                      ? 'Connected'
                      : (_joining ? 'Connecting…' : 'Connect / Volunteer'),
                  icon: Icons.handshake_outlined,
                  onPressed: joined || _joining ? null : _join,
                )
              else
                const Text(
                  'This agency partners with approved organizations. '
                  'Connect with a nonprofit or association to contribute.',
                  style: TextStyle(color: TqColors.slate),
                ),
              const SizedBox(height: 28),
              const SectionHeader(title: 'Published work'),
              const SizedBox(height: 8),
              Text(
                'Issues and projects this group is mobilizing the public around.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TqColors.slate,
                    ),
              ),
              const SizedBox(height: 12),
              if (work.isEmpty)
                const Text(
                  'No published work yet.',
                  style: TextStyle(color: TqColors.slate),
                )
              else
                ...work.map(
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
