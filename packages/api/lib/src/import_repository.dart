import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:trail_queue_models/trail_queue_models.dart' as models;

import 'demo_store.dart';
import 'firebase_config.dart';
import 'firestore_paths.dart';

class ImportRepository {
  ImportRepository({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  bool get isConfigured => FirebaseConfig.isConfigured && _db != null;

  Future<models.ImportJob> startImport({
    required models.ImportSource source,
    required List<LatLng> polygon,
  }) async {
    final modelPolygon = polygon
        .map((p) => models.GeoPoint(p.latitude, p.longitude))
        .toList();

    if (!isConfigured) {
      final done = models.ImportJob(
        id: 'job-${DateTime.now().millisecondsSinceEpoch}',
        source: source,
        status: models.ImportJobStatus.completed,
        trailCount: 3,
        assetCount: 2,
        createdAt: DateTime.now(),
        completedAt: DateTime.now(),
        polygon: modelPolygon,
      );
      DemoStore.instance.importJobs.insert(0, done);
      return done;
    }

    final ref = _db!.collection(FirestorePaths.importJobs).doc();
    await ref.set({
      'source': source.name,
      'status': models.ImportJobStatus.pending.name,
      'polygon': polygon
          .map((p) => {'lat': p.latitude, 'lng': p.longitude})
          .toList(),
      'trail_count': 0,
      'asset_count': 0,
      'created_at': FieldValue.serverTimestamp(),
    });

    return models.ImportJob(
      id: ref.id,
      source: source,
      status: models.ImportJobStatus.pending,
      createdAt: DateTime.now(),
      polygon: modelPolygon,
    );
  }

  Future<List<models.ImportJob>> listJobs() async {
    if (!isConfigured) {
      return List<models.ImportJob>.from(DemoStore.instance.importJobs);
    }

    final snap = await _db!
        .collection(FirestorePaths.importJobs)
        .orderBy('created_at', descending: true)
        .limit(20)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return models.ImportJob(
        id: d.id,
        source: models.ImportSource.values.firstWhere(
          (s) => s.name == data['source'],
          orElse: () => models.ImportSource.osm,
        ),
        status: models.ImportJobStatus.values.firstWhere(
          (s) => s.name == data['status'],
          orElse: () => models.ImportJobStatus.pending,
        ),
        trailCount: data['trail_count'] as int? ?? 0,
        assetCount: data['asset_count'] as int? ?? 0,
        errorMessage: data['error_message'] as String?,
        createdAt: (data['created_at'] as Timestamp?)?.toDate(),
      );
    }).toList();
  }
}
