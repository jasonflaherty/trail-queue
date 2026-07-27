import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

enum PendingMutationKind {
  createIssue,
  updateStatus,
  addToQueue,
  acceptIssue,
  addComment,
}

class PendingMutation {
  PendingMutation({
    required this.id,
    required this.kind,
    required this.payload,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  final String id;
  final PendingMutationKind kind;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int attempts;
  final String? lastError;

  PendingMutation copyWith({int? attempts, String? lastError}) {
    return PendingMutation(
      id: id,
      kind: kind,
      payload: payload,
      createdAt: createdAt,
      attempts: attempts ?? this.attempts,
      lastError: lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'payload': payload,
        'created_at': createdAt.toIso8601String(),
        'attempts': attempts,
        'last_error': lastError,
      };

  factory PendingMutation.fromJson(Map<String, dynamic> json) {
    return PendingMutation(
      id: json['id'] as String,
      kind: PendingMutationKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => PendingMutationKind.createIssue,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      attempts: json['attempts'] as int? ?? 0,
      lastError: json['last_error'] as String?,
    );
  }
}

class WorkAreaCache {
  const WorkAreaCache({
    required this.id,
    required this.label,
    required this.centerLat,
    required this.centerLng,
    required this.radiusMiles,
    required this.downloadedAt,
    this.issueCount = 0,
    this.trailCount = 0,
    this.assetCount = 0,
  });

  final String id;
  final String label;
  final double centerLat;
  final double centerLng;
  final double radiusMiles;
  final DateTime downloadedAt;
  final int issueCount;
  final int trailCount;
  final int assetCount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'center_lat': centerLat,
        'center_lng': centerLng,
        'radius_miles': radiusMiles,
        'downloaded_at': downloadedAt.toIso8601String(),
        'issue_count': issueCount,
        'trail_count': trailCount,
        'asset_count': assetCount,
      };

  factory WorkAreaCache.fromJson(Map<String, dynamic> json) {
    return WorkAreaCache(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Work area',
      centerLat: (json['center_lat'] as num).toDouble(),
      centerLng: (json['center_lng'] as num).toDouble(),
      radiusMiles: (json['radius_miles'] as num?)?.toDouble() ?? 10,
      downloadedAt:
          DateTime.tryParse(json['downloaded_at'] as String? ?? '') ??
              DateTime.now(),
      issueCount: json['issue_count'] as int? ?? 0,
      trailCount: json['trail_count'] as int? ?? 0,
      assetCount: json['asset_count'] as int? ?? 0,
    );
  }
}

/// Local-first Hive cache for issues, trails, assets, photos, and pending sync.
class OfflineStore {
  OfflineStore._();

  static final OfflineStore instance = OfflineStore._();

  static const _issuesBoxName = 'tq_issues_cache';
  static const _trailsBoxName = 'tq_trails_cache';
  static const _assetsBoxName = 'tq_assets_cache';
  static const _mutationsBoxName = 'tq_pending_mutations';
  static const _metaBoxName = 'tq_offline_meta';
  static const _photosBoxName = 'tq_photo_queue';

  Box<dynamic>? _issuesBox;
  Box<dynamic>? _trailsBox;
  Box<dynamic>? _assetsBox;
  Box<dynamic>? _mutationsBox;
  Box<dynamic>? _metaBox;
  Box<dynamic>? _photosBox;
  bool _initialized = false;

  final _mutationController = StreamController<int>.broadcast();
  final _connectivityController = StreamController<bool>.broadcast();

  bool get isInitialized => _initialized;
  Stream<int> get pendingCountStream => _mutationController.stream;
  Stream<bool> get onlineStream => _connectivityController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    _issuesBox = await Hive.openBox<dynamic>(_issuesBoxName);
    _trailsBox = await Hive.openBox<dynamic>(_trailsBoxName);
    _assetsBox = await Hive.openBox<dynamic>(_assetsBoxName);
    _mutationsBox = await Hive.openBox<dynamic>(_mutationsBoxName);
    _metaBox = await Hive.openBox<dynamic>(_metaBoxName);
    _photosBox = await Hive.openBox<dynamic>(_photosBoxName);
    _initialized = true;
    _mutationController.add(await pendingCount());
  }

  void setOnline(bool online) {
    if (_isOnline == online) return;
    _isOnline = online;
    _connectivityController.add(online);
  }

  Future<void> cacheIssues(List<TrailIssue> issues) async {
    await _ensureReady();
    final byId = <String, Map<String, dynamic>>{};
    for (final issue in issues) {
      byId[issue.id] = issue.toJson();
    }
    await _issuesBox!.put('issues_by_id', byId);
    await _issuesBox!.put('issues', issues.map((i) => i.toJson()).toList());
    await _metaBox!.put('issues_cached_at', DateTime.now().toIso8601String());
  }

  Future<void> upsertIssue(TrailIssue issue) async {
    await _ensureReady();
    final issues = await getCachedIssues();
    final index = issues.indexWhere((i) => i.id == issue.id);
    if (index >= 0) {
      issues[index] = issue;
    } else {
      issues.insert(0, issue);
    }
    await cacheIssues(issues);
  }

  Future<List<TrailIssue>> getCachedIssues() async {
    await _ensureReady();
    final raw = _issuesBox!.get('issues');
    if (raw is! List) {
      // Seed from demo data on first launch so offline works immediately.
      final seeded = DemoData.issues.map((i) => i.copyWith()).toList();
      await cacheIssues(seeded);
      return seeded;
    }
    return raw
        .cast<Map>()
        .map((m) => TrailIssue.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<TrailIssue?> getCachedIssue(String id) async {
    final issues = await getCachedIssues();
    try {
      return issues.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheTrails(List<Trail> trails) async {
    await _ensureReady();
    await _trailsBox!.put('trails', trails.map((t) => t.toJson()).toList());
    await _metaBox!.put('trails_cached_at', DateTime.now().toIso8601String());
  }

  Future<List<Trail>> getCachedTrails() async {
    await _ensureReady();
    final raw = _trailsBox!.get('trails');
    if (raw is! List) {
      final seeded = List<Trail>.from(DemoData.trails);
      await cacheTrails(seeded);
      return seeded;
    }
    return raw
        .cast<Map>()
        .map((m) => Trail.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> cacheAssets(List<TrailAsset> assets) async {
    await _ensureReady();
    await _assetsBox!.put('assets', assets.map((a) => a.toJson()).toList());
  }

  Future<List<TrailAsset>> getCachedAssets() async {
    await _ensureReady();
    final raw = _assetsBox!.get('assets');
    if (raw is! List) {
      final seeded = List<TrailAsset>.from(DemoData.assets);
      await cacheAssets(seeded);
      return seeded;
    }
    return raw
        .cast<Map>()
        .map((m) => TrailAsset.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> queueMutation(PendingMutation mutation) async {
    await _ensureReady();
    final existing = await getPendingMutations();
    existing.add(mutation);
    await _saveMutations(existing);
  }

  Future<List<PendingMutation>> getPendingMutations() async {
    await _ensureReady();
    final raw = _mutationsBox!.get('mutations');
    if (raw is! List) return [];
    return raw
        .cast<Map>()
        .map((m) => PendingMutation.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<int> pendingCount() async {
    return (await getPendingMutations()).length;
  }

  Future<void> replacePendingMutations(List<PendingMutation> mutations) async {
    await _saveMutations(mutations);
  }

  Future<void> clearPendingMutations() async {
    await _ensureReady();
    await _mutationsBox!.delete('mutations');
    _mutationController.add(0);
  }

  Future<void> removeMutation(String id) async {
    final remaining =
        (await getPendingMutations()).where((m) => m.id != id).toList();
    await _saveMutations(remaining);
  }

  Future<void> queuePhoto({
    required String localId,
    required String localPath,
    String? issueId,
  }) async {
    await _ensureReady();
    final photos = await getQueuedPhotos();
    photos.add({
      'local_id': localId,
      'local_path': localPath,
      'issue_id': issueId,
      'created_at': DateTime.now().toIso8601String(),
      'synced': false,
    });
    await _photosBox!.put('photos', photos);
  }

  Future<List<Map<String, dynamic>>> getQueuedPhotos() async {
    await _ensureReady();
    final raw = _photosBox!.get('photos');
    if (raw is! List) return [];
    return raw
        .cast<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  Future<void> markPhotoSynced(String localId, String remoteUrl) async {
    final photos = await getQueuedPhotos();
    for (var i = 0; i < photos.length; i++) {
      if (photos[i]['local_id'] == localId) {
        photos[i]['synced'] = true;
        photos[i]['remote_url'] = remoteUrl;
      }
    }
    await _photosBox!.put('photos', photos);
  }

  Future<WorkAreaCache?> getWorkArea() async {
    await _ensureReady();
    final raw = _metaBox!.get('work_area');
    if (raw is! Map) return null;
    return WorkAreaCache.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> saveWorkArea(WorkAreaCache area) async {
    await _ensureReady();
    await _metaBox!.put('work_area', area.toJson());
  }

  Future<DateTime?> lastSyncedAt() async {
    await _ensureReady();
    final raw = _metaBox!.get('last_synced_at') as String?;
    return DateTime.tryParse(raw ?? '');
  }

  Future<void> markSyncedNow() async {
    await _ensureReady();
    await _metaBox!.put('last_synced_at', DateTime.now().toIso8601String());
  }

  /// Download a work area: persist issues/trails/assets within radius.
  Future<WorkAreaCache> downloadWorkArea({
    required String label,
    required double latitude,
    required double longitude,
    double radiusMiles = 15,
    required List<TrailIssue> issues,
    required List<Trail> trails,
    required List<TrailAsset> assets,
  }) async {
    await cacheIssues(issues);
    await cacheTrails(trails);
    await cacheAssets(assets);
    final area = WorkAreaCache(
      id: 'area-${DateTime.now().millisecondsSinceEpoch}',
      label: label,
      centerLat: latitude,
      centerLng: longitude,
      radiusMiles: radiusMiles,
      downloadedAt: DateTime.now(),
      issueCount: issues.length,
      trailCount: trails.length,
      assetCount: assets.length,
    );
    await saveWorkArea(area);
    // Mark tile region intent for map package consumers.
    await _metaBox!.put('tile_region', {
      'lat': latitude,
      'lng': longitude,
      'radius_miles': radiusMiles,
      'downloaded_at': area.downloadedAt.toIso8601String(),
    });
    return area;
  }

  Future<void> _saveMutations(List<PendingMutation> mutations) async {
    await _ensureReady();
    await _mutationsBox!.put(
      'mutations',
      mutations.map((m) => m.toJson()).toList(),
    );
    _mutationController.add(mutations.length);
  }

  Future<void> _ensureReady() async {
    if (!_initialized) await init();
  }

  Future<void> dispose() async {
    await _mutationController.close();
    await _connectivityController.close();
  }
}
