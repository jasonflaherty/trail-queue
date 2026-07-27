import 'package:trail_queue_models/trail_queue_models.dart';

class ScoreService {
  MaintenanceScoreBreakdown computeForTrail(
    String trailId,
    List<TrailIssue> openIssues,
  ) {
    final trailIssues =
        openIssues.where((i) => i.trailId == trailId && i.status != IssueStatus.closed);

    final count = trailIssues.length;
    if (count == 0) {
      return MaintenanceScoreBreakdown(
        trailId: trailId,
        score: 95,
        grade: MaintenanceGrade.excellent,
      );
    }

    final now = DateTime.now();
    final ages = trailIssues
        .map((i) => now.difference(i.createdAt ?? now).inDays.toDouble())
        .toList();
    final averageAge =
        ages.isEmpty ? 0.0 : ages.reduce((a, b) => a + b) / ages.length;

    final severityWeight = trailIssues.fold<double>(0, (sum, issue) {
      return sum +
          switch (issue.priority) {
            IssuePriority.critical => 25,
            IssuePriority.high => 15,
            IssuePriority.medium => 8,
            IssuePriority.low => 3,
          };
    });

    final score = (100 -
            (count * 4) -
            (averageAge * 0.5) -
            (severityWeight * 0.3))
        .clamp(0, 100)
        .toDouble();

    return MaintenanceScoreBreakdown(
      trailId: trailId,
      score: score,
      grade: MaintenanceScoreBreakdown.gradeFromScore(score),
      openIssueCount: count,
      averageIssueAgeDays: averageAge,
      severityWeight: severityWeight,
      inspectionFactor: count > 3 ? 10 : 0,
      recentWorkFactor: averageAge > 14 ? 8 : 0,
      volunteerActivityFactor: count > 5 ? 5 : 0,
    );
  }

  List<MaintenanceScoreBreakdown> computeAll(
    List<Trail> trails,
    List<TrailIssue> openIssues,
  ) {
    return trails
        .map((trail) => computeForTrail(trail.id, openIssues))
        .toList();
  }
}
