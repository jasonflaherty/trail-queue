import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trail_queue_models/trail_queue_models.dart' hide GeoPoint;

import 'firebase_config.dart';
import 'firestore_paths.dart';

class AssetRepository {
  AssetRepository({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  bool get isConfigured => FirebaseConfig.isConfigured && _db != null;

  Future<List<TrailAsset>> listForTrail(String trailId) async {
    if (!isConfigured) {
      return DemoData.assets.where((a) => a.trailId == trailId).toList();
    }

    final snap = await _db!
        .collection(FirestorePaths.assets)
        .where('trail_id', isEqualTo: trailId)
        .get();
    return snap.docs.map(_fromDoc).toList();
  }

  Future<List<TrailAsset>> listNearby({
    required double latitude,
    required double longitude,
  }) async {
    if (!isConfigured) {
      return List<TrailAsset>.from(DemoData.assets);
    }

    final snap = await _db!.collection(FirestorePaths.assets).get();
    return snap.docs.map(_fromDoc).toList();
  }

  TrailAsset _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    data['id'] = doc.id;
    final geo = data['location'];
    if (geo is GeoPoint) {
      data['lat'] = geo.latitude;
      data['lng'] = geo.longitude;
    }
    return TrailAsset.fromJson(data);
  }
}
