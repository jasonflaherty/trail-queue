import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import 'cluster_marker.dart';
import 'overlays.dart';
import 'tile_providers.dart';

/// Default map center near Mt. Hood, Oregon.
const kDefaultMapCenter = LatLng(45.37, -121.70);

class TrailMapView extends StatefulWidget {
  const TrailMapView({
    super.key,
    this.center = kDefaultMapCenter,
    this.initialZoom = 11,
    this.basemap = BasemapType.osm,
    this.trails = const [],
    this.issues = const [],
    this.polygonPoints = const [],
    this.overlays = const [],
    this.showTrails = true,
    this.showIssues = true,
    this.onIssueTap,
    this.onTrailTap,
    this.onMapTap,
    this.onLongPress,
    this.onOverlayTap,
    this.onSearchTap,
    this.onSearchChanged,
    this.onBasemapChanged,
    this.onLocationTap,
    this.onPolygonPointAdded,
  });

  final LatLng center;
  final double initialZoom;
  final BasemapType basemap;
  final List<Trail> trails;
  final List<TrailIssue> issues;
  final List<LatLng> polygonPoints;
  final List<MapOverlayFeature> overlays;
  final bool showTrails;
  final bool showIssues;
  final ValueChanged<TrailIssue>? onIssueTap;
  final ValueChanged<Trail>? onTrailTap;
  final ValueChanged<LatLng>? onMapTap;
  final ValueChanged<LatLng>? onLongPress;
  final ValueChanged<MapOverlayFeature>? onOverlayTap;
  final VoidCallback? onSearchTap;
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<BasemapType>? onBasemapChanged;
  final VoidCallback? onLocationTap;
  final ValueChanged<LatLng>? onPolygonPointAdded;

  @override
  State<TrailMapView> createState() => _TrailMapViewState();
}

class _TrailMapViewState extends State<TrailMapView> {
  late final MapController _mapController;
  late BasemapType _basemap;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _basemap = widget.basemap;
  }

  @override
  void didUpdateWidget(covariant TrailMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.basemap != widget.basemap) {
      _basemap = widget.basemap;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.center,
            initialZoom: widget.initialZoom,
            onTap: (tapPosition, point) {
              final overlay = _overlayAt(point);
              if (overlay != null) {
                widget.onOverlayTap?.call(overlay);
                return;
              }
              widget.onMapTap?.call(point);
              widget.onPolygonPointAdded?.call(point);
            },
            onLongPress: (tapPosition, point) {
              widget.onLongPress?.call(point);
            },
          ),
          children: [
            TileProviders.tileLayer(_basemap),
            if (widget.overlays.isNotEmpty) _buildOverlayLayer(),
            if (widget.showTrails) _buildTrailLayer(),
            if (widget.polygonPoints.isNotEmpty) _buildPolygonLayer(),
            if (widget.showIssues) _buildIssueLayer(),
          ],
        ),
        _buildSearchOverlay(context),
        _buildNorthButton(context),
        _buildFloatingControls(context),
      ],
    );
  }

  MapOverlayFeature? _overlayAt(LatLng point) {
    // Prefer fire perimeters; last drawn / top-most wins.
    for (final overlay in widget.overlays.reversed) {
      if (overlay.points.length < 3) continue;
      if (_pointInPolygon(point, overlay.points)) return overlay;
    }
    return null;
  }

  /// Ray-casting point-in-polygon test.
  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final pi = polygon[i];
      final pj = polygon[j];
      final intersect = ((pi.latitude > point.latitude) !=
              (pj.latitude > point.latitude)) &&
          (point.longitude <
              (pj.longitude - pi.longitude) *
                      (point.latitude - pi.latitude) /
                      (pj.latitude - pi.latitude) +
                  pi.longitude);
      if (intersect) inside = !inside;
    }
    return inside;
  }

  Widget _buildOverlayLayer() {
    return PolygonLayer(
      polygons: widget.overlays
          .where((o) => o.points.length >= 3)
          .map(
            (o) => Polygon(
              points: o.points,
              color: (o.kind == OverlayKind.fire
                      ? Colors.deepOrange
                      : Colors.blue)
                  .withValues(alpha: 0.25),
              borderColor: o.kind == OverlayKind.fire
                  ? Colors.deepOrange
                  : Colors.blueAccent,
              borderStrokeWidth: 2,
              label: o.label,
            ),
          )
          .toList(),
    );
  }

  Widget _buildTrailLayer() {
    return PolylineLayer(
      polylines: widget.trails
          .where((trail) => trail.geometry.length >= 2)
          .map(
            (trail) => Polyline(
              points: trail.geometry,
              strokeWidth: 3,
              color: TqColors.forestGreen,
              borderStrokeWidth: 1,
              borderColor: Colors.white,
            ),
          )
          .toList(),
    );
  }

  Widget _buildPolygonLayer() {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: widget.polygonPoints,
          color: TqColors.forestGreen.withValues(alpha: 0.15),
          borderColor: TqColors.forestGreen,
          borderStrokeWidth: 2,
        ),
      ],
    );
  }

  Widget _buildIssueLayer() {
    final clusters = _clusterIssues(widget.issues);

    return MarkerLayer(
      markers: clusters.entries.map((entry) {
        final point = entry.key;
        final clusterIssues = entry.value;
        final first = clusterIssues.first;

        return Marker(
          point: point,
          width: 40,
          height: 40,
          alignment: Alignment.center,
          child: ClusterMarker(
            count: clusterIssues.length,
            onTap: () {
              if (clusterIssues.length == 1) {
                widget.onIssueTap?.call(first);
              } else {
                widget.onIssueTap?.call(first);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Map<LatLng, List<TrailIssue>> _clusterIssues(List<TrailIssue> issues) {
    const precision = 3;
    final clusters = <String, List<TrailIssue>>{};

    for (final issue in issues) {
      final lat = issue.location.latitude.toStringAsFixed(precision);
      final lng = issue.location.longitude.toStringAsFixed(precision);
      final key = '$lat,$lng';
      clusters.putIfAbsent(key, () => []).add(issue);
    }

    return clusters.map(
      (key, value) => MapEntry(
        LatLng(
          value.first.location.latitude,
          value.first.location.longitude,
        ),
        value,
      ),
    );
  }

  Widget _buildSearchOverlay(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 12,
      left: 16,
      right: 16,
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        child: TextField(
          controller: _searchController,
          onTap: widget.onSearchTap,
          onChanged: widget.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search trails or issues',
            prefixIcon: const Icon(Icons.search),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildNorthButton(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 68,
      left: 16,
      child: _MapControlButton(
        icon: Icons.navigation,
        tooltip: 'North',
        onPressed: () {
          final camera = _mapController.camera;
          _mapController.moveAndRotate(camera.center, camera.zoom, 0);
        },
      ),
    );
  }

  Widget _buildFloatingControls(BuildContext context) {
    // Always clear the shell bottom tab bar + home indicator.
    final bottomClearance =
        MediaQuery.viewPaddingOf(context).bottom + kBottomNavigationBarHeight + 12;
    return Positioned(
      right: 16,
      bottom: bottomClearance,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _MapControlButton(
            icon: Icons.layers_outlined,
            tooltip: 'Basemap',
            onPressed: _showBasemapPicker,
          ),
          const SizedBox(height: 8),
          _MapControlButton(
            icon: Icons.add,
            tooltip: 'Zoom in',
            onPressed: () {
              final camera = _mapController.camera;
              _mapController.move(camera.center, camera.zoom + 1);
            },
          ),
          const SizedBox(height: 8),
          _MapControlButton(
            icon: Icons.remove,
            tooltip: 'Zoom out',
            onPressed: () {
              final camera = _mapController.camera;
              _mapController.move(camera.center, camera.zoom - 1);
            },
          ),
          const SizedBox(height: 8),
          _MapControlButton(
            icon: Icons.my_location,
            tooltip: 'My location',
            onPressed: () {
              widget.onLocationTap?.call();
              _mapController.move(widget.center, widget.initialZoom);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showBasemapPicker() async {
    final selected = await showModalBottomSheet<BasemapType>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Basemap',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              ...TileProviders.all.map(
                (type) => ListTile(
                  title: Text(type.label),
                  trailing: _basemap == type
                      ? Icon(Icons.check, color: TqColors.forestGreen)
                      : null,
                  onTap: () => Navigator.pop(context, type),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected == null) return;
    setState(() => _basemap = selected);
    widget.onBasemapChanged?.call(selected);
  }
}

class _MapControlButton extends StatelessWidget {
  const _MapControlButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      shape: const CircleBorder(),
      color: Theme.of(context).colorScheme.surface,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: TqColors.forestGreen),
        onPressed: onPressed,
      ),
    );
  }
}
