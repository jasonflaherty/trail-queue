import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

import 'demo_store.dart';
import 'firebase_config.dart';
import 'firestore_paths.dart';
import 'offline_store.dart';

class TrailRepository {
  TrailRepository({
    FirebaseFirestore? firestore,
    OfflineStore? offlineStore,
  })  : _db = firestore,
        _offline = offlineStore ?? OfflineStore.instance;

  final FirebaseFirestore? _db;
  final OfflineStore _offline;

  bool get isConfigured => FirebaseConfig.isConfigured && _db != null;

  Future<List<Trail>> list() async {
    final cached = await _offline.getCachedTrails();

    if (_offline.isOnline && isConfigured) {
      try {
        final snap =
            await _db!.collection(FirestorePaths.trails).orderBy('name').get();
        final trails = snap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return Trail.fromJson(data);
        }).toList();
        await _offline.cacheTrails(trails);
        return trails;
      } catch (_) {
        return cached;
      }
    }

    if (cached.isNotEmpty) return cached;
    return List<Trail>.from(DemoStore.instance.trails);
  }

  Future<Trail?> getById(String id) async {
    final all = await list();
    try {
      return all.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Trail>> trailsInPolygon(List<LatLng> polygon) async {
    final all = await list();
    if (polygon.length < 3) return all;

    return all.where((trail) {
      if (trail.geometry.isEmpty) return false;
      return trail.geometry.any((point) => _pointInPolygon(point, polygon));
    }).toList();
  }

  Future<void> upsertTrail(Trail trail) async {
    if (!isConfigured) {
      final trails = DemoStore.instance.trails;
      final i = trails.indexWhere((t) => t.id == trail.id);
      if (i >= 0) {
        trails[i] = trail;
      } else {
        trails.add(trail);
      }
      await _offline.cacheTrails(trails);
      return;
    }

    await _db!
        .collection(FirestorePaths.trails)
        .doc(trail.id)
        .set(trail.toJson(), SetOptions(merge: true));
  }

  bool _pointInPolygon(LatLng point, List<LatLng> polygon) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final xi = polygon[i].longitude;
      final yi = polygon[i].latitude;
      final xj = polygon[j].longitude;
      final yj = polygon[j].latitude;

      final intersects = ((yi > point.latitude) != (yj > point.latitude)) &&
          (point.longitude <
              (xj - xi) * (point.latitude - yi) / (yj - yi + 0.0) + xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }
}
