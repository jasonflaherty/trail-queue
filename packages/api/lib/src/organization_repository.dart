import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trail_queue_models/trail_queue_models.dart' hide GeoPoint;

import 'demo_store.dart';
import 'firebase_config.dart';
import 'firestore_paths.dart';

class OrganizationRepository {
  OrganizationRepository({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  bool get isConfigured => FirebaseConfig.isConfigured && _db != null;

  Future<List<Organization>> list() async {
    if (!isConfigured) {
      return List<Organization>.from(DemoStore.instance.organizations);
    }

    final snap =
        await _db!.collection(FirestorePaths.organizations).orderBy('name').get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return Organization.fromJson(data);
    }).toList();
  }

  Future<Organization?> getById(String id) async {
    final orgs = await list();
    try {
      return orgs.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<TrailIssue>> publishedWork(String organizationId) async {
    if (!isConfigured) {
      return DemoStore.instance.issues
          .where((i) => i.status != IssueStatus.closed)
          .toList();
    }

    final snap = await _db!
        .collection(FirestorePaths.issues)
        .where('status', isEqualTo: 'open')
        .orderBy('created_at', descending: true)
        .limit(20)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      final geo = data['location'];
      if (geo is GeoPoint) {
        data['lat'] = geo.latitude;
        data['lng'] = geo.longitude;
      }
      return TrailIssue.fromJson(data);
    }).toList();
  }

  Future<Organization> approve(String id) async {
    if (!isConfigured) {
      final store = DemoStore.instance;
      final index = store.organizations.indexWhere((o) => o.id == id);
      if (index < 0) throw StateError('Organization not found');
      final current = store.organizations[index];
      final updated = Organization(
        id: current.id,
        name: current.name,
        description: current.description,
        approved: true,
        memberCount: current.memberCount,
        trailCount: current.trailCount,
        openWorkCount: current.openWorkCount,
        website: current.website,
        kind: current.kind,
        region: current.region,
        acceptingVolunteers: current.acceptingVolunteers,
      );
      store.organizations[index] = updated;
      return updated;
    }

    await _db!.collection(FirestorePaths.organizations).doc(id).set({
      'approved': true,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final doc =
        await _db.collection(FirestorePaths.organizations).doc(id).get();
    final data = doc.data()!;
    data['id'] = doc.id;
    return Organization.fromJson(data);
  }
}
