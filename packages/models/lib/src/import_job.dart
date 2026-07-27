import 'package:equatable/equatable.dart';

import 'enums.dart';
import 'user_profile.dart';

class ImportJob extends Equatable {
  const ImportJob({
    required this.id,
    required this.source,
    required this.status,
    this.trailCount = 0,
    this.assetCount = 0,
    this.errorMessage,
    this.createdAt,
    this.completedAt,
    this.polygon = const [],
  });

  final String id;
  final ImportSource source;
  final ImportJobStatus status;
  final int trailCount;
  final int assetCount;
  final String? errorMessage;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final List<GeoPoint> polygon;

  @override
  List<Object?> get props => [id, source, status, trailCount];
}
