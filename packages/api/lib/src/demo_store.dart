import 'package:trail_queue_models/trail_queue_models.dart';

/// In-memory demo data store seeded from [DemoData] for offline development.
class DemoStore {
  DemoStore._();

  static final DemoStore instance = DemoStore._();

  final List<TrailIssue> issues =
      DemoData.issues.map((i) => i.copyWith()).toList();
  final List<Trail> trails =
      DemoData.trails.map((t) => t).toList(growable: true);
  final List<Crew> crews = DemoData.crews.map((c) => c).toList(growable: true);
  final List<Organization> organizations =
      DemoData.organizations.map((o) => o).toList(growable: true);
  final List<NotificationItem> notifications = DemoData.notifications
      .map((n) => NotificationItem(
            id: n.id,
            kind: n.kind,
            title: n.title,
            body: n.body,
            createdAt: n.createdAt,
            read: n.read,
            relatedId: n.relatedId,
          ))
      .toList(growable: true);
  final List<ImportJob> importJobs = <ImportJob>[];

  UserProfile? currentUser;

  int _issueCounter = 5000;

  String nextIssueId() => 'issue-${++_issueCounter}';

  int nextIssueNumber() => _issueCounter;

  void upsertIssue(TrailIssue issue) {
    final index = issues.indexWhere((i) => i.id == issue.id);
    if (index >= 0) {
      issues[index] = issue;
    } else {
      issues.insert(0, issue);
    }
  }
}
