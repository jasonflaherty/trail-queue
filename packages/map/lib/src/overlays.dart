import 'package:latlong2/latlong.dart';

/// Simple GeoJSON-like overlay feature for weather advisories / fire perimeters.
class MapOverlayFeature {
  const MapOverlayFeature({
    required this.id,
    required this.label,
    required this.kind,
    this.points = const [],
    this.severity = OverlaySeverity.info,
  });

  final String id;
  final String label;
  final OverlayKind kind;
  final List<LatLng> points;
  final OverlaySeverity severity;
}

enum OverlayKind { weather, fire }

enum OverlaySeverity { info, watch, warning, critical }

/// Demo overlays near Mt. Hood for NOAA/NWS and InciWeb-style layers.
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
      label: 'InciWeb: Demo Fire Perimeter',
      kind: OverlayKind.fire,
      severity: OverlaySeverity.warning,
      points: const [
        LatLng(45.30, -121.80),
        LatLng(45.31, -121.78),
        LatLng(45.29, -121.77),
        LatLng(45.28, -121.79),
      ],
    ),
  ];
}
