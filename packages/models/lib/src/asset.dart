import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'user_profile.dart';

class TrailAsset extends Equatable {
  const TrailAsset({
    required this.id,
    required this.type,
    required this.location,
    this.name,
    this.trailId,
    this.notes,
  });

  final String id;
  final AssetType type;
  final GeoPoint location;
  final String? name;
  final String? trailId;
  final String? notes;

  factory TrailAsset.fromJson(Map<String, dynamic> json) {
    return TrailAsset(
      id: json['id'] as String,
      type: AssetType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AssetType.sign,
      ),
      location: GeoPoint(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      name: json['name'] as String?,
      trailId: json['trail_id'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'lat': location.latitude,
        'lng': location.longitude,
        'name': name,
        'trail_id': trailId,
        'notes': notes,
      };

  @override
  List<Object?> get props => [id, type, location];
}
