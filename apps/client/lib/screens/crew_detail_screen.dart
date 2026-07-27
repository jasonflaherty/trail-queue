import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class CrewDetailScreen extends ConsumerStatefulWidget {
  const CrewDetailScreen({super.key, required this.crewId});

  final String crewId;

  @override
  ConsumerState<CrewDetailScreen> createState() => _CrewDetailScreenState();
}

class _CrewDetailScreenState extends ConsumerState<CrewDetailScreen> {
  final _messageController = TextEditingController();
  final _messages = <CrewMessage>[
    CrewMessage(
      id: 'm1',
      crewId: 'crew-hood',
      authorName: 'Alex',
      body: 'Bringing extra loppers for the blowdown section.',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    CrewMessage(
      id: 'm2',
      crewId: 'crew-hood',
      authorName: 'Jordan',
      body: 'Trailhead parking fills by 8:30 — carpool if you can.',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage(String crewId) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(authUserProvider).valueOrNull;
    setState(() {
      _messages.add(
        CrewMessage(
          id: 'm-${DateTime.now().millisecondsSinceEpoch}',
          crewId: crewId,
          authorName: user?.displayName ?? 'You',
          body: text,
          createdAt: DateTime.now(),
        ),
      );
      _messageController.clear();
    });
  }

  Future<void> _assignIssue(String crewId) async {
    final issues = await ref.read(issuesProvider.future);
    if (!mounted || issues.isEmpty) return;

    final selected = await showModalBottomSheet<TrailIssue>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: issues.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final issue = issues[index];
              return ListTile(
                title: Text(issue.title),
                subtitle: Text(issue.trailName ?? 'Unknown trail'),
                onTap: () => Navigator.pop(context, issue),
              );
            },
          ),
        );
      },
    );

    if (selected == null) return;
    await ref.read(servicesProvider).issues.acceptIssue(selected.id);
    refreshIssueData(ref);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assigned ${selected.title} to crew workday')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final crewsAsync = ref.watch(crewsProvider);
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    return crewsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: EmptyState(title: 'Could not load crew', message: error.toString()),
      ),
      data: (crews) {
        final crew = crews.cast<Crew?>().firstWhere(
              (c) => c!.id == widget.crewId,
              orElse: () => null,
            );
        if (crew == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(title: 'Crew not found'),
          );
        }

        return Scaffold(
          appBar: AppBar(title: Text(crew.name)),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${crew.memberCount} members',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (crew.description != null) ...[
                        const SizedBox(height: 8),
                        Text(crew.description!),
                      ],
                      if (crew.leaderName != null) ...[
                        const SizedBox(height: 8),
                        Text('Leader: ${crew.leaderName}'),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Upcoming Workday'),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.event, color: TqColors.forestGreen),
                  title: Text(
                    crew.nextEventAt != null
                        ? dateFormat.format(crew.nextEventAt!)
                        : 'Schedule a workday',
                  ),
                  subtitle: const Text('Calendar integration coming soon'),
                ),
              ),
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Crew Chat',
                actionLabel: 'Assign issue',
                onAction: () => _assignIssue(crew.id),
              ),
              const SizedBox(height: 8),
              ..._messages.map(
                (message) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? TqColors.darkCard
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.authorName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: TqColors.forestGreen,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(message.body),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat.jm().format(message.createdAt),
                            style: const TextStyle(
                              color: TqColors.slate,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Message the crew…',
                      ),
                      onSubmitted: (_) => _sendMessage(crew.id),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _sendMessage(crew.id),
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: TqColors.forestGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
