import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class CrewsScreen extends ConsumerStatefulWidget {
  const CrewsScreen({super.key});

  @override
  ConsumerState<CrewsScreen> createState() => _CrewsScreenState();
}

class _CrewsScreenState extends ConsumerState<CrewsScreen> {
  Future<void> _createCrew() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Crew'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Crew name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (created != true || nameController.text.trim().isEmpty) return;

    final user = ref.read(authUserProvider).valueOrNull;
    await ref.read(servicesProvider).crews.create(
          Crew(
            id: 'crew-${DateTime.now().millisecondsSinceEpoch}',
            name: nameController.text.trim(),
            description: descController.text.trim(),
            leaderId: user?.id,
            leaderName: user?.displayName,
            memberCount: 1,
          ),
        );
    ref.invalidate(crewsProvider);
  }

  Future<void> _inviteCrew(String crewId, String crewName) async {
    final emailController = TextEditingController();
    final invited = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Invite to $crewName'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );

    if (invited != true || emailController.text.trim().isEmpty) return;

    await ref.read(servicesProvider).crews.invite(
          crewId: crewId,
          crewName: crewName,
          email: emailController.text.trim(),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final crewsAsync = ref.watch(crewsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crews'),
        actions: [
          IconButton(
            onPressed: _createCrew,
            icon: const Icon(Icons.add),
            tooltip: 'Create crew',
          ),
        ],
      ),
      body: crewsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => EmptyState(
          title: 'Could not load crews',
          message: error.toString(),
        ),
        data: (crews) {
          if (crews.isEmpty) {
            return EmptyState(
              title: 'No crews yet',
              message: 'Create a crew to coordinate trail work.',
              action: TqPrimaryButton(
                label: 'Create Crew',
                onPressed: _createCrew,
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: crews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final crew = crews[index];
              return Card(
                child: ListTile(
                  title: Text(
                    crew.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    [
                      '${crew.memberCount} members',
                      if (crew.description != null) crew.description!,
                    ].join(' • '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'invite') {
                        _inviteCrew(crew.id, crew.name);
                      } else if (value == 'open') {
                        context.push('/crews/${crew.id}');
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'open', child: Text('Open crew')),
                      PopupMenuItem(value: 'invite', child: Text('Invite member')),
                    ],
                  ),
                  onTap: () => context.push('/crews/${crew.id}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
