import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:test/test.dart';

void main() {
  group('IssueType', () {
    test('report grid has eight primary buckets', () {
      expect(IssueType.reportGrid, hasLength(8));
      expect(IssueType.reportGrid, contains(IssueType.blowdown));
      expect(IssueType.reportGrid, contains(IssueType.other));
    });
  });

  group('TrailIssue', () {
    test('secondary types round-trip through json', () {
      const issue = TrailIssue(
        id: 'i1',
        title: 'Blowdown with washout below',
        type: IssueType.blowdown,
        secondaryTypes: [IssueType.washout, IssueType.drainageBlocked],
        priority: IssuePriority.high,
        status: IssueStatus.open,
        location: GeoPoint(45.3, -121.7),
      );

      final restored = TrailIssue.fromJson(issue.toJson());
      expect(restored.type, IssueType.blowdown);
      expect(
        restored.secondaryTypes,
        [IssueType.washout, IssueType.drainageBlocked],
      );
      expect(restored.allTypes.first, IssueType.blowdown);
      expect(restored.allTypes, hasLength(3));
    });
  });

  group('MaintenanceScoreBreakdown', () {
    test('grades from score thresholds', () {
      expect(
        MaintenanceScoreBreakdown.gradeFromScore(90),
        MaintenanceGrade.excellent,
      );
      expect(
        MaintenanceScoreBreakdown.gradeFromScore(65),
        MaintenanceGrade.needsAttention,
      );
      expect(
        MaintenanceScoreBreakdown.gradeFromScore(45),
        MaintenanceGrade.significantBacklog,
      );
      expect(
        MaintenanceScoreBreakdown.gradeFromScore(10),
        MaintenanceGrade.critical,
      );
    });
  });

  group('DemoData', () {
    test('seeds Mt. Hood area issues and trails', () {
      expect(DemoData.trails, isNotEmpty);
      expect(DemoData.issues, isNotEmpty);
      expect(DemoData.crews, isNotEmpty);
      expect(DemoData.currentUser.displayName, 'Alex');
    });
  });
}
