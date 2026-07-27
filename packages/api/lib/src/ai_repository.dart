import 'package:trail_queue_models/trail_queue_models.dart';

import 'demo_store.dart';

class AiRepository {
  Future<AiIssueSuggestion> classifyIssue({
    required String title,
    String? description,
  }) async {
    final text = '${title.toLowerCase()} ${description?.toLowerCase() ?? ''}';

    IssueType type = IssueType.other;
    IssuePriority priority = IssuePriority.medium;
    final tools = <String>[];

    if (text.contains('tree') ||
        text.contains('blowdown') ||
        text.contains('fallen')) {
      type = IssueType.blowdown;
      priority = IssuePriority.high;
      tools.addAll(['Crosscut saw', 'Loppers']);
    } else if (text.contains('erosion') || text.contains('washout')) {
      type = text.contains('washout') ? IssueType.washout : IssueType.erosion;
      priority = IssuePriority.medium;
      tools.addAll(['McLeod', 'Pulaski', 'Shovel']);
    } else if (text.contains('bridge') || text.contains('plank')) {
      type = text.contains('plank')
          ? IssueType.missingBridgePlank
          : IssueType.bridgeDamage;
      priority = IssuePriority.critical;
      tools.addAll(['Drill', 'Lag bolts']);
    } else if (text.contains('sign')) {
      type = text.contains('broken') || text.contains('damaged')
          ? IssueType.brokenSign
          : IssueType.missingSign;
      priority = IssuePriority.low;
      tools.addAll(['Drill', 'Screws']);
    } else if (text.contains('drain') || text.contains('water')) {
      type = IssueType.drainageBlocked;
      priority = IssuePriority.medium;
      tools.add('Shovel');
    } else if (text.contains('rock') || text.contains('slide')) {
      type = IssueType.rockSlide;
      priority = IssuePriority.high;
      tools.addAll(['Rock bar', 'Shovel']);
    } else if (text.contains('brush')) {
      type = IssueType.brushOvergrowth;
      priority = IssuePriority.low;
      tools.add('Loppers');
    }

    final demoMatch = DemoData.issues.cast<TrailIssue?>().firstWhere(
          (issue) =>
              issue!.title.toLowerCase().contains(title.toLowerCase()) ||
              title.toLowerCase().contains(issue.title.toLowerCase()),
          orElse: () => null,
        );
    if (demoMatch != null) {
      type = demoMatch.type;
      priority = demoMatch.priority;
      tools
        ..clear()
        ..addAll(demoMatch.requiredTools);
    }

    return AiIssueSuggestion(
      type: type,
      priority: priority,
      crewSize: _crewSizeFor(type),
      estimatedHours: _hoursFor(type),
      requiredTools: tools.isEmpty ? ['Hand tools'] : tools,
      safetyConcerns: priority == IssuePriority.critical
          ? 'Assess structural safety before work begins.'
          : null,
      confidence: demoMatch != null ? 0.92 : 0.74,
    );
  }

  Future<List<TrailIssue>> findDuplicates(TrailIssue draft) async {
    final issues = DemoStore.instance.issues;
    return issues.where((existing) {
      if (existing.trailId != null &&
          draft.trailId != null &&
          existing.trailId != draft.trailId) {
        return false;
      }
      if (existing.type != draft.type) return false;

      final latDiff =
          (existing.location.latitude - draft.location.latitude).abs();
      final lngDiff =
          (existing.location.longitude - draft.location.longitude).abs();
      return latDiff < 0.01 && lngDiff < 0.01;
    }).toList();
  }

  Future<List<TrailIssue>> planWorkday({
    required List<TrailIssue> candidates,
    int maxIssues = 4,
    double? maxHours,
  }) async {
    final budget = maxHours ?? 8;
    final sorted = List<TrailIssue>.from(candidates)
      ..sort((a, b) {
        final priorityCompare =
            b.priority.index.compareTo(a.priority.index);
        if (priorityCompare != 0) return priorityCompare;
        return (a.estimatedHours ?? 2).compareTo(b.estimatedHours ?? 2);
      });

    final plan = <TrailIssue>[];
    var hoursUsed = 0.0;

    for (final issue in sorted) {
      if (plan.length >= maxIssues) break;
      final hours = issue.estimatedHours ?? 2;
      if (hoursUsed + hours > budget) continue;
      plan.add(issue);
      hoursUsed += hours;
    }

    return plan;
  }

  int _crewSizeFor(IssueType type) => switch (type) {
        IssueType.blowdown => 2,
        IssueType.erosion || IssueType.washout => 4,
        IssueType.missingBridgePlank || IssueType.bridgeDamage => 3,
        IssueType.missingSign || IssueType.brokenSign => 1,
        _ => 2,
      };

  double _hoursFor(IssueType type) => switch (type) {
        IssueType.blowdown => 3,
        IssueType.erosion || IssueType.washout => 6,
        IssueType.missingBridgePlank || IssueType.bridgeDamage => 4,
        IssueType.missingSign || IssueType.brokenSign => 1,
        _ => 2,
      };
}
