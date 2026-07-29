import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'overlays.dart';

/// Fetches NOAA/NWS weather alerts and NIFC WFIGS fire perimeters.
class OverlayService {
  OverlayService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _userAgent = 'TrailQueue/0.1 (https://github.com/jasonflaherty/trail-queue)';
  static const _nwsBase = 'https://api.weather.gov';
  static const _nifcPerimeters =
      'https://services3.arcgis.com/T4QMspbfLg3qTGWY/arcgis/rest/services/'
      'WFIGS_Interagency_Perimeters_Current/FeatureServer/0/query';

  Map<String, String> get _headers => {
        'User-Agent': _userAgent,
        'Accept': 'application/geo+json, application/json',
      };

  /// Active NWS watches/warnings near [center], falling back to demo data.
  Future<List<MapOverlayFeature>> fetchWeatherOverlays({
    required LatLng center,
    double radiusMiles = 80,
  }) async {
    try {
      final uri = Uri.parse('$_nwsBase/alerts/active').replace(
        queryParameters: {
          'status': 'actual',
          'message_type': 'alert',
          'point':
              '${center.latitude.toStringAsFixed(4)},${center.longitude.toStringAsFixed(4)}',
        },
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return OverlayDemoData.weather;
      }
      final features = _parseGeoJsonOverlays(
        jsonDecode(response.body) as Map<String, dynamic>,
        kind: OverlayKind.weather,
        nameKeys: const ['event', 'headline'],
      );
      if (features.isEmpty) return OverlayDemoData.weather;
      return features;
    } catch (_) {
      return OverlayDemoData.weather;
    }
  }

  /// Current wildland fire perimeters from NIFC WFIGS, clipped near [center].
  Future<List<MapOverlayFeature>> fetchFireOverlays({
    required LatLng center,
    double radiusMiles = 250,
  }) async {
    try {
      final delta = radiusMiles / 69.0;
      final minLng = center.longitude - delta;
      final minLat = center.latitude - delta;
      final maxLng = center.longitude + delta;
      final maxLat = center.latitude + delta;
      final uri = Uri.parse(_nifcPerimeters).replace(
        queryParameters: {
          'where': '1=1',
          'outFields':
              'poly_IncidentName,poly_GISAcres,attr_PercentContained,'
              'attr_FireDiscoveryDateTime,attr_POOState',
          'geometry': '$minLng,$minLat,$maxLng,$maxLat',
          'geometryType': 'esriGeometryEnvelope',
          'inSR': '4326',
          'spatialRel': 'esriSpatialRelIntersects',
          'outSR': '4326',
          'geometryPrecision': '3',
          'resultRecordCount': '40',
          'f': 'geojson',
        },
      );
      final response = await _client
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        return OverlayDemoData.fires;
      }
      final features = _parseGeoJsonOverlays(
        jsonDecode(response.body) as Map<String, dynamic>,
        kind: OverlayKind.fire,
        nameKeys: const ['poly_IncidentName', 'IncidentName'],
      );
      if (features.isEmpty) return OverlayDemoData.fires;
      return features;
    } catch (_) {
      return OverlayDemoData.fires;
    }
  }

  /// Point forecast + active alerts for a long-press location (NOAA/NWS).
  Future<WeatherPointReport> fetchWeatherAt(LatLng point) async {
    try {
      final pointsUri = Uri.parse(
        '$_nwsBase/points/${point.latitude.toStringAsFixed(4)},'
        '${point.longitude.toStringAsFixed(4)}',
      );
      final pointsRes = await _client
          .get(pointsUri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      if (pointsRes.statusCode != 200) {
        throw StateError('NWS points ${pointsRes.statusCode}');
      }
      final pointsJson = jsonDecode(pointsRes.body) as Map<String, dynamic>;
      final props = pointsJson['properties'] as Map<String, dynamic>? ?? {};
      final forecastUrl = props['forecast'] as String?;
      final city = (props['relativeLocation'] as Map?)?['properties']
          as Map<String, dynamic>?;
      final place = [
        if (city?['city'] != null) city!['city'],
        if (city?['state'] != null) city!['state'],
      ].join(', ');

      String? summary;
      String? temperature;
      String? wind;
      String? shortForecast;
      final forecastDays = <ForecastDay>[];
      if (forecastUrl != null) {
        final forecastRes = await _client
            .get(Uri.parse(forecastUrl), headers: _headers)
            .timeout(const Duration(seconds: 10));
        if (forecastRes.statusCode == 200) {
          final forecastJson =
              jsonDecode(forecastRes.body) as Map<String, dynamic>;
          final periods = (forecastJson['properties']
                  as Map<String, dynamic>?)?['periods'] as List? ??
              const [];
          if (periods.isNotEmpty) {
            final period = periods.first as Map<String, dynamic>;
            shortForecast = period['shortForecast'] as String?;
            summary = period['detailedForecast'] as String?;
            final temp = period['temperature'];
            final unit = period['temperatureUnit'] ?? 'F';
            if (temp != null) temperature = '$temp°$unit';
            wind =
                '${period['windSpeed'] ?? ''} ${period['windDirection'] ?? ''}'
                    .trim();

            // Build up to 3 day summaries (high / low / wind / wx).
            final byDay = <String, _DayBucket>{};
            for (final raw in periods) {
              final p = raw as Map<String, dynamic>;
              final start = DateTime.tryParse(p['startTime'] as String? ?? '');
              if (start == null) continue;
              final local = start.toLocal();
              final key =
                  '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
              final isDay = p['isDaytime'] as bool? ?? true;
              final temp = (p['temperature'] as num?)?.round();
              final unit = (p['temperatureUnit'] as String?) ?? 'F';
              final windStr =
                  '${p['windSpeed'] ?? ''} ${p['windDirection'] ?? ''}'.trim();
              final wx = p['shortForecast'] as String? ?? '';
              final bucket = byDay.putIfAbsent(
                key,
                () => _DayBucket(
                  label: _weekdayLabel(local, byDay.length),
                  unit: unit,
                ),
              );
              if (temp != null) {
                bucket.high = bucket.high == null
                    ? temp
                    : (temp > bucket.high! ? temp : bucket.high);
                bucket.low = bucket.low == null
                    ? temp
                    : (temp < bucket.low! ? temp : bucket.low);
              }
              if (isDay) {
                if (wx.isNotEmpty) bucket.wx = wx;
                if (windStr.isNotEmpty) bucket.wind = windStr;
              } else {
                bucket.wx ??= wx.isEmpty ? null : wx;
                bucket.wind ??= windStr.isEmpty ? null : windStr;
              }
            }
            for (final bucket in byDay.values.take(3)) {
              forecastDays.add(
                ForecastDay(
                  label: bucket.label,
                  high: bucket.high == null ? null : '${bucket.high}°${bucket.unit}',
                  low: bucket.low == null ? null : '${bucket.low}°${bucket.unit}',
                  wind: bucket.wind,
                  shortForecast: bucket.wx ?? '',
                ),
              );
            }
          }
        }
      }

      final alertsUri = Uri.parse('$_nwsBase/alerts/active').replace(
        queryParameters: {
          'status': 'actual',
          'point':
              '${point.latitude.toStringAsFixed(4)},${point.longitude.toStringAsFixed(4)}',
        },
      );
      final alertsRes = await _client
          .get(alertsUri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      final alerts = <WeatherAlert>[];
      if (alertsRes.statusCode == 200) {
        final alertsJson = jsonDecode(alertsRes.body) as Map<String, dynamic>;
        for (final raw in (alertsJson['features'] as List? ?? const [])) {
          final feature = raw as Map<String, dynamic>;
          final p = feature['properties'] as Map<String, dynamic>? ?? {};
          alerts.add(
            WeatherAlert(
              event: p['event'] as String? ?? 'Alert',
              headline: p['headline'] as String? ?? '',
              severity: p['severity'] as String? ?? 'Unknown',
              description: p['description'] as String? ?? '',
            ),
          );
        }
      }

      return WeatherPointReport(
        latitude: point.latitude,
        longitude: point.longitude,
        placeName: place.isEmpty ? null : place,
        shortForecast: shortForecast,
        detailedForecast: summary,
        temperature: temperature,
        wind: wind?.isEmpty == true ? null : wind,
        forecast: forecastDays,
        alerts: alerts,
      );
    } catch (e) {
      return WeatherPointReport(
        latitude: point.latitude,
        longitude: point.longitude,
        error: 'Could not reach NOAA/NWS ($e)',
      );
    }
  }

  List<MapOverlayFeature> _parseGeoJsonOverlays(
    Map<String, dynamic> collection, {
    required OverlayKind kind,
    required List<String> nameKeys,
  }) {
    final out = <MapOverlayFeature>[];
    final features = collection['features'] as List? ?? const [];
    for (var i = 0; i < features.length; i++) {
      final feature = features[i] as Map<String, dynamic>;
      final props = feature['properties'] as Map<String, dynamic>? ?? {};
      final geometry = feature['geometry'] as Map<String, dynamic>?;
      if (geometry == null) continue;

      String label = 'Unknown';
      for (final key in nameKeys) {
        final value = props[key];
        if (value is String && value.trim().isNotEmpty) {
          label = value.trim();
          break;
        }
      }

      double? sizeAcres;
      double? percentContained;
      DateTime? discoveredAt;
      String? state;
      if (kind == OverlayKind.fire) {
        final acres = props['poly_GISAcres'];
        if (acres is num) sizeAcres = acres.toDouble();
        final contained = props['attr_PercentContained'];
        if (contained is num) percentContained = contained.toDouble();
        state = props['attr_POOState'] as String?;
        discoveredAt = _parseNifcDate(props['attr_FireDiscoveryDateTime']);
      }

      final rings = _ringsFromGeometry(geometry);
      for (var r = 0; r < rings.length; r++) {
        final points = rings[r];
        if (points.length < 3) continue;
        // Cap vertices for map performance.
        final simplified = points.length > 120
            ? [
                for (var j = 0; j < points.length; j +=
                    math.max(1, points.length ~/ 100))
                  points[j],
                points.last,
              ]
            : points;
        out.add(
          MapOverlayFeature(
            id: '${kind.name}-$i-$r',
            label: label,
            kind: kind,
            severity: kind == OverlayKind.fire
                ? OverlaySeverity.warning
                : _weatherSeverity(props['severity'] as String?),
            points: simplified,
            discoveredAt: discoveredAt,
            sizeAcres: sizeAcres,
            percentContained: percentContained,
            state: state,
          ),
        );
      }
    }
    return out;
  }

  DateTime? _parseNifcDate(Object? raw) {
    if (raw == null) return null;
    if (raw is num) {
      // ArcGIS epoch ms
      return DateTime.fromMillisecondsSinceEpoch(raw.round(), isUtc: true)
          .toLocal();
    }
    if (raw is String) {
      final asNum = num.tryParse(raw);
      if (asNum != null) {
        return DateTime.fromMillisecondsSinceEpoch(asNum.round(), isUtc: true)
            .toLocal();
      }
      return DateTime.tryParse(raw)?.toLocal();
    }
    return null;
  }

  List<List<LatLng>> _ringsFromGeometry(Map<String, dynamic> geometry) {
    final type = geometry['type'] as String?;
    final coords = geometry['coordinates'];
    if (coords is! List) return const [];

    List<LatLng> ring(List raw) {
      return raw
          .whereType<List>()
          .where((c) => c.length >= 2)
          .map(
            (c) => LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ),
          )
          .toList();
    }

    switch (type) {
      case 'Polygon':
        // First ring is exterior.
        if (coords.isEmpty) return const [];
        return [ring(coords.first as List)];
      case 'MultiPolygon':
        return [
          for (final poly in coords.whereType<List>())
            if (poly.isNotEmpty) ring(poly.first as List),
        ];
      default:
        return const [];
    }
  }

  OverlaySeverity _weatherSeverity(String? severity) {
    return switch ((severity ?? '').toLowerCase()) {
      'extreme' || 'severe' => OverlaySeverity.critical,
      'moderate' => OverlaySeverity.warning,
      'minor' => OverlaySeverity.watch,
      _ => OverlaySeverity.info,
    };
  }

  String _weekdayLabel(DateTime local, int index) {
    if (index == 0) return 'Today';
    if (index == 1) return 'Tomorrow';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[local.weekday - 1];
  }
}

class _DayBucket {
  _DayBucket({required this.label, required this.unit});

  final String label;
  final String unit;
  int? high;
  int? low;
  String? wind;
  String? wx;
}

class WeatherAlert {
  const WeatherAlert({
    required this.event,
    required this.headline,
    required this.severity,
    required this.description,
  });

  final String event;
  final String headline;
  final String severity;
  final String description;
}

class ForecastDay {
  const ForecastDay({
    required this.label,
    required this.shortForecast,
    this.high,
    this.low,
    this.wind,
  });

  final String label;
  final String? high;
  final String? low;
  final String? wind;
  final String shortForecast;
}

class WeatherPointReport {
  const WeatherPointReport({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.shortForecast,
    this.detailedForecast,
    this.temperature,
    this.wind,
    this.forecast = const [],
    this.alerts = const [],
    this.error,
  });

  final double latitude;
  final double longitude;
  final String? placeName;
  final String? shortForecast;
  final String? detailedForecast;
  final String? temperature;
  final String? wind;
  final List<ForecastDay> forecast;
  final List<WeatherAlert> alerts;
  final String? error;

  bool get hasForecast =>
      forecast.isNotEmpty ||
      shortForecast != null ||
      detailedForecast != null ||
      temperature != null;
}
