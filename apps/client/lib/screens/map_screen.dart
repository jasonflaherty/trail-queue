import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
  final _overlayService = OverlayService();

  bool _importLoading = false;
  bool _showFire = false;
  bool _loadingFire = false;
  bool _loadingPointWeather = false;

  List<MapOverlayFeature> _fireOverlays = const [];

  List<TrailIssue> _filterIssues(List<TrailIssue> issues, MapFilter filter) {
    return switch (filter) {
      MapFilter.allIssues => issues,
      MapFilter.high =>
        issues.where((i) => i.priority == IssuePriority.high).toList(),
      MapFilter.medium =>
        issues.where((i) => i.priority == IssuePriority.medium).toList(),
      MapFilter.low =>
        issues.where((i) => i.priority == IssuePriority.low).toList(),
      MapFilter.trails => const [],
    };
  }

  Future<void> _toggleFire() async {
    final next = !_showFire;
    setState(() {
      _showFire = next;
      if (!next) _fireOverlays = const [];
    });
    if (!next) return;
    setState(() => _loadingFire = true);
    try {
      final overlays = await _overlayService.fetchFireOverlays(
        center: kDefaultMapCenter,
      );
      if (mounted) setState(() => _fireOverlays = overlays);
    } finally {
      if (mounted) setState(() => _loadingFire = false);
    }
  }

  Future<void> _onOverlayTap(MapOverlayFeature overlay) async {
    if (!overlay.isFire) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _FireDetailSheet(fire: overlay),
    );
  }

  Future<void> _onLongPress(LatLng point) async {
    setState(() => _loadingPointWeather = true);
    final reportFuture = _overlayService.fetchWeatherAt(point);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return FutureBuilder<WeatherPointReport>(
          future: reportFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Expanded(child: Text('Fetching NOAA / NWS weather…')),
                    ],
                  ),
                ),
              );
            }
            return _WeatherReportSheet(report: snapshot.data!);
          },
        );
      },
    );
    if (mounted) setState(() => _loadingPointWeather = false);
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
      if (_showFire) ..._fireOverlays,
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
            showTrails:
                filter == MapFilter.trails || filter == MapFilter.allIssues,
            showIssues: filter != MapFilter.trails,
            polygonPoints: polygonPoints,
            onIssueTap: (issue) => context.push('/issues/${issue.id}'),
            onTrailTap: (trail) => context.push('/trails/${trail.id}'),
            onBasemapChanged: (type) =>
                ref.read(basemapProvider.notifier).state = type,
            onLongPress: _onLongPress,
            onOverlayTap: _onOverlayTap,
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
            child: _OverlayToggle(
              label: _loadingFire ? '…' : 'Fires',
              selected: _showFire,
              color: Colors.deepOrange,
              onTap: _loadingFire ? null : _toggleFire,
            ),
          ),
          if (_loadingPointWeather)
            const Positioned(
              left: 16,
              right: 16,
              bottom: 120,
              child: Material(
                elevation: 2,
                borderRadius: BorderRadius.all(Radius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Long-press: loading NOAA weather…',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          Positioned(
            left: 16,
            right: 16,
            bottom: canImport && polygon.length >= 3 ? 96 : 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Long-press map for NOAA weather at that point',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black54,
                        backgroundColor: Colors.white70,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FilterChipRow(
                  selected: filter,
                  onSelected: (value) =>
                      ref.read(mapFilterProvider.notifier).state = value,
                ),
              ],
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

class _FireDetailSheet extends StatelessWidget {
  const _FireDetailSheet({required this.fire});

  final MapOverlayFeature fire;

  @override
  Widget build(BuildContext context) {
    final dateLabel = fire.discoveredAt == null
        ? 'Unknown'
        : DateFormat.yMMMd().format(fire.discoveredAt!);
    final sizeLabel = fire.sizeAcres == null
        ? 'Unknown'
        : '${NumberFormat('#,##0').format(fire.sizeAcres!.round())} acres';
    final containmentLabel = fire.percentContained == null
        ? 'Unknown'
        : '${fire.percentContained!.round()}%';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department, color: Colors.deepOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    fire.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            if (fire.state != null) ...[
              const SizedBox(height: 4),
              Text(
                fire.state!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TqColors.slate,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            _FireDetailRow(label: 'Discovery date', value: dateLabel),
            _FireDetailRow(label: 'Current size', value: sizeLabel),
            _FireDetailRow(label: 'Containment', value: containmentLabel),
            const SizedBox(height: 12),
            Text(
              'Source: NIFC WFIGS current fire perimeters. '
              'Informational only — not for evacuation decisions.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: TqColors.slate,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FireDetailRow extends StatelessWidget {
  const _FireDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: TqColors.slate,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastDayChip extends StatelessWidget {
  const _ForecastDayChip({required this.day});

  final ForecastDay day;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final hiLo = [
      if (day.high != null) 'H ${day.high}',
      if (day.low != null) 'L ${day.low}',
    ].join('  ');
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, height: 1.2),
          ),
          const SizedBox(height: 2),
          Text(
            hiLo.isEmpty ? '—' : hiLo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, height: 1.2),
          ),
          if (day.shortForecast.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              day.shortForecast,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, height: 1.2, color: muted),
            ),
          ],
          if (day.wind != null && day.wind!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              day.wind!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, height: 1.2, color: muted),
            ),
          ],
        ],
      ),
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
  final VoidCallback? onTap;

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

class _WeatherReportSheet extends StatelessWidget {
  const _WeatherReportSheet({required this.report});

  final WeatherPointReport report;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOAA / NWS Weather',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                report.placeName ??
                    '${report.latitude.toStringAsFixed(4)}, '
                        '${report.longitude.toStringAsFixed(4)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TqColors.slate,
                    ),
              ),
              if (report.error != null) ...[
                const SizedBox(height: 16),
                Text(report.error!, style: const TextStyle(color: Colors.red)),
              ] else ...[
                if (report.temperature != null || report.shortForecast != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      [
                        if (report.temperature != null) report.temperature!,
                        if (report.shortForecast != null) report.shortForecast!,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                if (report.wind != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Wind ${report.wind}'),
                  ),
                if (report.detailedForecast != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(report.detailedForecast!),
                  ),
                if (report.forecast.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    '3-day forecast',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (var i = 0; i < report.forecast.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          _ForecastDayChip(day: report.forecast[i]),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  'Active alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                if (report.alerts.isEmpty)
                  const Text(
                    'No active watches or warnings at this point.',
                    style: TextStyle(color: TqColors.slate),
                  )
                else
                  ...report.alerts.map(
                    (alert) => Card(
                      child: ListTile(
                        leading: Icon(
                          Icons.warning_amber_rounded,
                          color: alert.severity.toLowerCase() == 'extreme' ||
                                  alert.severity.toLowerCase() == 'severe'
                              ? Colors.red
                              : Colors.orange,
                        ),
                        title: Text(alert.event),
                        subtitle: Text(
                          alert.headline.isEmpty
                              ? alert.severity
                              : alert.headline,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Text(
                'Source: National Weather Service (api.weather.gov). '
                'Informational only — not for life-safety decisions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: TqColors.slate,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
