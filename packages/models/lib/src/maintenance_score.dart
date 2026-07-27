import 'package:equatable/equatable.dart';

import 'enums.dart';

class MaintenanceScoreBreakdown extends Equatable {
  const MaintenanceScoreBreakdown({
    required this.trailId,
    required this.score,
    required this.grade,
    this.openIssueCount = 0,
    this.averageIssueAgeDays = 0,
    this.severityWeight = 0,
    this.inspectionFactor = 0,
    this.recentWorkFactor = 0,
    this.volunteerActivityFactor = 0,
  });

  final String trailId;
  final double score;
  final MaintenanceGrade grade;
  final int openIssueCount;
  final double averageIssueAgeDays;
  final double severityWeight;
  final double inspectionFactor;
  final double recentWorkFactor;
  final double volunteerActivityFactor;

  static MaintenanceGrade gradeFromScore(double score) {
    if (score >= 80) return MaintenanceGrade.excellent;
    if (score >= 60) return MaintenanceGrade.needsAttention;
    if (score >= 40) return MaintenanceGrade.significantBacklog;
    return MaintenanceGrade.critical;
  }

  @override
  List<Object?> get props => [trailId, score, grade];
}
