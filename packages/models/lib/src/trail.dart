import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

import 'enums.dart';

class Trail extends Equatable {
  const Trail({
    required this.id,
    required this.name,
    this.agency,
    this.lengthMiles,
    this.elevationGainFt,
    this.difficulty = TrailDifficulty.moderate,
    this.surface,
    this.allowedUses = const [],
    this.trailNumber,
    this.maintenanceLevel,
    this.motorized = false,
    this.maintenanceScore,
    this.maintenanceGrade,
    this.openIssueCount = 0,
    this.closedIssueCount = 0,
    this.geometry = const [],
    this.photoUrls = const [],
    this.source,
  });

  final String id;
  final String name;
  final String? agency;
  final double? lengthMiles;
  final double? elevationGainFt;
  final TrailDifficulty difficulty;
  final String? surface;
  final List<String> allowedUses;
  final String? trailNumber;
  final String? maintenanceLevel;
  final bool motorized;
  final double? maintenanceScore;
  final MaintenanceGrade? maintenanceGrade;
  final int openIssueCount;
  final int closedIssueCount;
  final List<LatLng> geometry;
  final List<String> photoUrls;
  final ImportSource? source;

  factory Trail.fromJson(Map<String, dynamic> json) {
    final geom = <LatLng>[];
    final rawGeom = json['geometry'];
    if (rawGeom is List) {
      for (final p in rawGeom) {
        if (p is Map) {
          final lat = (p['lat'] as num?)?.toDouble();
          final lng = (p['lng'] as num?)?.toDouble();
          if (lat != null && lng != null) geom.add(LatLng(lat, lng));
        }
      }
    }
    return Trail(
      id: json['id'] as String,
      name: json['name'] as String? ?? 'Unnamed Trail',
      agency: json['agency'] as String?,
      lengthMiles: (json['length_miles'] as num?)?.toDouble(),
      elevationGainFt: (json['elevation_gain_ft'] as num?)?.toDouble(),
      trailNumber: json['trail_number'] as String?,
      surface: json['surface'] as String?,
      openIssueCount: json['open_issue_count'] as int? ?? 0,
      closedIssueCount: json['closed_issue_count'] as int? ?? 0,
      maintenanceScore: (json['maintenance_score'] as num?)?.toDouble(),
      geometry: geom,
      photoUrls: (json['photo_urls'] as List?)?.cast<String>() ?? const [],
      allowedUses: (json['allowed_uses'] as List?)?.cast<String>() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'agency': agency,
        'length_miles': lengthMiles,
        'elevation_gain_ft': elevationGainFt,
        'surface': surface,
        'trail_number': trailNumber,
        'open_issue_count': openIssueCount,
        'closed_issue_count': closedIssueCount,
        'maintenance_score': maintenanceScore,
        'geometry': geometry
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'photo_urls': photoUrls,
        'allowed_uses': allowedUses,
      };

  @override
  List<Object?> get props => [id, name, agency, openIssueCount];
}

class TrailSummary extends Equatable {
  const TrailSummary({
    required this.id,
    required this.name,
    required this.difficulty,
    this.lengthMiles,
  });

  final String id;
  final String name;
  final TrailDifficulty difficulty;
  final double? lengthMiles;

  @override
  List<Object?> get props => [id, name];
}
