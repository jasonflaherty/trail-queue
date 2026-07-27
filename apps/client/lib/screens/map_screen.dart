import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_map/trail_queue_map.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  bool _importLoading = false;
  bool _showWeather = false;
  bool _showFire = false;

  List<TrailIssue> _filterIssues(List<TrailIssue> issues, MapFilter filter) {
    return switch (filter) {
      MapFilter.allIssues => issues,
      MapFilter.high => issues.where((i) => i.priority == IssuePriority.high).toList(),
      MapFilter.medium =>
        issues.where((i) => i.priority == IssuePriority.medium).toList(),
      MapFilter.low => issues.where((i) => i.priority == IssuePriority.low).toList(),
      MapFilter.trails => const [],
    };
  }

  Future<void> _showImportSheet(List<GeoPoint> polygon) async {
    final user = ref.read(authUserProvider).valueOrNull;
    if (user == null || !user.canImport) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Import requires land manager or admin role.'),
          ),
        );
      }
      return;
    }

    final latLngPolygon = polygon.map((p) => p.toLatLng()).toList();
    final trails =
        await ref.read(servicesProvider).trails.trailsInPolygon(latLngPolygon);
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return ImportTrailsSheet(
          trails: trails,
          source: trails.isNotEmpty ? trails.first.source : ImportSource.osm,
          isLoading: _importLoading,
          onImport: () async {
            setState(() => _importLoading = true);
            try {
              await ref.read(servicesProvider).imports.startImport(
                    source: trails.isNotEmpty
                        ? trails.first.source ?? ImportSource.osm
                        : ImportSource.osm,
                    polygon: latLngPolygon,
                  );
              ref.invalidate(importJobsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Import started')),
                );
              }
            } finally {
              if (mounted) setState(() => _importLoading = false);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(mapFilterProvider);
    final basemap = ref.watch(basemapProvider);
    final polygon = ref.watch(polygonPointsProvider);
    final polygonPoints = polygon.map((p) => p.toLatLng()).toList();
    final issuesAsync = ref.watch(issuesProvider);
    final trailsAsync = ref.watch(trailsProvider);
    final user = ref.watch(authUserProvider).valueOrNull;
    final canImport = user?.canImport ?? false;

    final issues = issuesAsync.maybeWhen(
      data: (items) => _filterIssues(items, filter),
      orElse: () => const <TrailIssue>[],
    );
    final trails = trailsAsync.maybeWhen(
      data: (items) => items,
      orElse: () => const <Trail>[],
    );

    final overlays = <MapOverlayFeature>[
      if (_showWeather) ...OverlayDemoData.weather,
      if (_showFire) ...OverlayDemoData.fires,
    ];

    return Scaffold(
      body: Stack(
        children: [
          TrailMapView(
            basemap: basemap,
            trails: filter == MapFilter.trails || filter == MapFilter.allIssues
                ? trails
                : const [],
            issues: filter == MapFilter.trails ? const [] : issues,
            overlays: overlays,
            showTrails: filter == MapFilter.trails || filter == MapFilter.allIssues,
            showIssues: filter != MapFilter.trails,
            polygonPoints: polygonPoints,
            onIssueTap: (issue) => context.push('/issues/${issue.id}'),
            onTrailTap: (trail) => context.push('/trails/${trail.id}'),
            onBasemapChanged: (type) =>
                ref.read(basemapProvider.notifier).state = type,
            onPolygonPointAdded: (point) {
              ref.read(polygonPointsProvider.notifier).update(
                    (points) => [
                      ...points,
                      GeoPoint(point.latitude, point.longitude),
                    ],
                  );
            },
          ),
          Positioned(
            top: MediaQuery.paddingOf(context).top + 72,
            right: 16,
            child: Column(
              children: [
                _OverlayToggle(
                  label: 'NWS',
                  selected: _showWeather,
                  color: Colors.blue,
                  onTap: () => setState(() => _showWeather = !_showWeather),
                ),
                const SizedBox(height: 8),
                _OverlayToggle(
                  label: 'Fire',
                  selected: _showFire,
                  color: Colors.deepOrange,
                  onTap: () => setState(() => _showFire = !_showFire),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: canImport && polygon.length >= 3 ? 96 : 24,
            child: FilterChipRow(
              selected: filter,
              onSelected: (value) =>
                  ref.read(mapFilterProvider.notifier).state = value,
            ),
          ),
          if (canImport && polygon.length >= 3)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: TqPrimaryButton(
                label: 'Import Trails in Area',
                icon: Icons.download_outlined,
                onPressed: () => _showImportSheet(polygon),
              ),
            ),
        ],
      ),
      floatingActionButton: canImport
          ? FloatingActionButton.extended(
              onPressed: () {
                ref.read(polygonPointsProvider.notifier).state = const [];
              },
              icon: Icon(
                polygon.isEmpty ? Icons.polyline_outlined : Icons.clear,
              ),
              label: Text(polygon.isEmpty ? 'Draw Area' : 'Clear Area'),
              backgroundColor: TqColors.forestGreen,
            )
          : null,
    );
  }
}

class _OverlayToggle extends StatelessWidget {
  const _OverlayToggle({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color : Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }
}
