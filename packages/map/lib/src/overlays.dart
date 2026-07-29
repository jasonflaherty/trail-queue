import 'package:latlong2/latlong.dart';

/// Simple GeoJSON-like overlay feature for weather advisories / fire perimeters.
class MapOverlayFeature {
  const MapOverlayFeature({
    required this.id,
    required this.label,
    required this.kind,
    this.points = const [],
    this.severity = OverlaySeverity.info,
    this.discoveredAt,
    this.sizeAcres,
    this.percentContained,
    this.state,
  });

  final String id;

  /// Display name (incident name for fires).
  final String label;
  final OverlayKind kind;
  final List<LatLng> points;
  final OverlaySeverity severity;

  /// Fire discovery / start date (NIFC).
  final DateTime? discoveredAt;

  /// Current perimeter size in acres (NIFC).
  final double? sizeAcres;

  /// Percent contained 0–100 (NIFC).
  final double? percentContained;

  /// Point of origin state, if known.
  final String? state;

  bool get isFire => kind == OverlayKind.fire;
}

enum OverlayKind { weather, fire }

enum OverlaySeverity { info, watch, warning, critical }

/// Demo overlays near Mt. Hood used when NOAA/NIFC network fetches fail.
class OverlayDemoData {
  OverlayDemoData._();

  static final weather = <MapOverlayFeature>[
    MapOverlayFeature(
      id: 'wx-wind',
      label: 'NWS Wind Advisory',
      kind: OverlayKind.weather,
      severity: OverlaySeverity.watch,
      points: const [
        LatLng(45.40, -121.75),
        LatLng(45.40, -121.65),
        LatLng(45.32, -121.65),
        LatLng(45.32, -121.75),
      ],
    ),
  ];

  static final fires = <MapOverlayFeature>[
    MapOverlayFeature(
      id: 'fire-demo',
      label: 'Demo Fire',
      kind: OverlayKind.fire,
      severity: OverlaySeverity.warning,
      discoveredAt: DateTime(2026, 7, 20),
      sizeAcres: 1240,
      percentContained: 35,
      state: 'OR',
      points: const [
        LatLng(45.30, -121.80),
        LatLng(45.31, -121.78),
        LatLng(45.29, -121.77),
        LatLng(45.28, -121.79),
      ],
    ),
  ];
}
