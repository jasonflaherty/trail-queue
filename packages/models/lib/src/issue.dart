import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'user_profile.dart';

class TrailIssue extends Equatable {
  const TrailIssue({
    required this.id,
    required this.title,
    required this.type,
    required this.priority,
    required this.status,
    required this.location,
    this.secondaryTypes = const [],
    this.description,
    this.trailId,
    this.trailName,
    this.assetId,
    this.photoUrls = const [],
    this.estimatedHours,
    this.estimatedCrewSize,
    this.estimatedDurationLabel,
    this.requiredTools = const [],
    this.requiredCertifications = const [],
    this.reportedById,
    this.reportedByName,
    this.agency,
    this.trailUses = const [],
    this.distanceMiles,
    this.issueNumber,
    this.createdAt,
    this.updatedAt,
    this.assignedToId,
    this.crewId,
    this.safetyNotes,
    this.inMyQueue = false,
  });

  final String id;
  final String title;
  final IssueType type;

  /// Additional conditions reported alongside the primary [type].
  final List<IssueType> secondaryTypes;
  final IssuePriority priority;
  final IssueStatus status;
  final GeoPoint location;
  final String? description;
  final String? trailId;
  final String? trailName;
  final String? assetId;
  final List<String> photoUrls;
  final double? estimatedHours;
  final int? estimatedCrewSize;
  final String? estimatedDurationLabel;
  final List<String> requiredTools;
  final List<String> requiredCertifications;
  final String? reportedById;
  final String? reportedByName;
  final String? agency;
  final List<String> trailUses;
  final double? distanceMiles;
  final int? issueNumber;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? assignedToId;
  final String? crewId;
  final String? safetyNotes;
  final bool inMyQueue;

  /// Every reported condition, primary first.
  List<IssueType> get allTypes => [type, ...secondaryTypes];

  String get priorityLabel => '${priority.label} Priority';

  String get issueIdLabel =>
      issueNumber != null ? 'Issue #$issueNumber' : 'Issue ${id.substring(0, 6)}';

  String get crewSizeLabel {
    final n = estimatedCrewSize ?? 2;
    return '$n–${n + 2} volunteers';
  }

  String get timeLabel => estimatedDurationLabel ??
      (estimatedHours != null
          ? '${estimatedHours!.toStringAsFixed(0)}–${(estimatedHours! + 2).toStringAsFixed(0)} hrs'
          : '2–4 hrs');

  TrailIssue copyWith({
    IssueStatus? status,
    IssuePriority? priority,
    bool? inMyQueue,
    String? assignedToId,
    String? crewId,
    List<String>? photoUrls,
    String? description,
  }) {
    return TrailIssue(
      id: id,
      title: title,
      type: type,
      secondaryTypes: secondaryTypes,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      location: location,
      description: description ?? this.description,
      trailId: trailId,
      trailName: trailName,
      assetId: assetId,
      photoUrls: photoUrls ?? this.photoUrls,
      estimatedHours: estimatedHours,
      estimatedCrewSize: estimatedCrewSize,
      estimatedDurationLabel: estimatedDurationLabel,
      requiredTools: requiredTools,
      requiredCertifications: requiredCertifications,
      reportedById: reportedById,
      reportedByName: reportedByName,
      agency: agency,
      trailUses: trailUses,
      distanceMiles: distanceMiles,
      issueNumber: issueNumber,
      createdAt: createdAt,
      updatedAt: updatedAt,
      assignedToId: assignedToId ?? this.assignedToId,
      crewId: crewId ?? this.crewId,
      safetyNotes: safetyNotes,
      inMyQueue: inMyQueue ?? this.inMyQueue,
    );
  }

  factory TrailIssue.fromJson(Map<String, dynamic> json) {
    return TrailIssue(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Untitled issue',
      type: IssueType.values.firstWhere(
        (e) => e.name == json['type'] || e.label == json['type'],
        orElse: () => IssueType.other,
      ),
      secondaryTypes: (json['secondary_types'] as List?)
              ?.map((raw) => IssueType.values.firstWhere(
                    (e) => e.name == raw || e.label == raw,
                    orElse: () => IssueType.other,
                  ))
              .toList() ??
          const [],
      priority: IssuePriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => IssuePriority.medium,
      ),
      status: IssueStatus.values.firstWhere(
        (e) => e.toDb() == json['status'] || e.name == json['status'],
        orElse: () => IssueStatus.open,
      ),
      location: GeoPoint(
        (json['lat'] as num?)?.toDouble() ?? 0,
        (json['lng'] as num?)?.toDouble() ?? 0,
      ),
      description: json['description'] as String?,
      trailId: json['trail_id'] as String?,
      trailName: json['trail_name'] as String?,
      photoUrls: (json['photo_urls'] as List?)?.cast<String>() ?? const [],
      estimatedHours: (json['estimated_hours'] as num?)?.toDouble(),
      estimatedCrewSize: json['estimated_crew_size'] as int?,
      reportedByName: json['reported_by_name'] as String?,
      agency: json['agency'] as String?,
      issueNumber: json['issue_number'] as int?,
      distanceMiles: (json['distance_miles'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'secondary_types': secondaryTypes.map((t) => t.name).toList(),
        'priority': priority.name,
        'status': status.toDb(),
        'lat': location.latitude,
        'lng': location.longitude,
        'description': description,
        'trail_id': trailId,
        'trail_name': trailName,
        'photo_urls': photoUrls,
        'estimated_hours': estimatedHours,
        'estimated_crew_size': estimatedCrewSize,
        'agency': agency,
        'issue_number': issueNumber,
      };

  @override
  List<Object?> get props => [id, title, type, priority, status, inMyQueue];
}

class IssueComment extends Equatable {
  const IssueComment({
    required this.id,
    required this.issueId,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.authorId,
  });

  final String id;
  final String issueId;
  final String? authorId;
  final String authorName;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, issueId, body];
}

class IssueHistoryEntry extends Equatable {
  const IssueHistoryEntry({
    required this.id,
    required this.issueId,
    required this.summary,
    required this.createdAt,
    this.actorName,
  });

  final String id;
  final String issueId;
  final String summary;
  final DateTime createdAt;
  final String? actorName;

  @override
  List<Object?> get props => [id, summary];
}

class AiIssueSuggestion extends Equatable {
  const AiIssueSuggestion({
    required this.type,
    required this.priority,
    this.crewSize,
    this.estimatedHours,
    this.requiredTools = const [],
    this.safetyConcerns,
    this.confidence,
  });

  final IssueType type;
  final IssuePriority priority;
  final int? crewSize;
  final double? estimatedHours;
  final List<String> requiredTools;
  final String? safetyConcerns;
  final double? confidence;

  @override
  List<Object?> get props => [type, priority, confidence];
}
