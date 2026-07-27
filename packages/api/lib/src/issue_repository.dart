import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trail_queue_models/trail_queue_models.dart' hide GeoPoint;

import 'demo_store.dart';
import 'firebase_config.dart';
import 'firestore_paths.dart';
import 'offline_store.dart';
import 'sync_service.dart';

class IssueRepository {
  IssueRepository({
    FirebaseFirestore? firestore,
    OfflineStore? offlineStore,
    SyncService? sync,
  })  : _db = firestore,
        _offline = offlineStore ?? OfflineStore.instance,
        _sync = sync;

  final FirebaseFirestore? _db;
  final OfflineStore _offline;
  SyncService? _sync;

  void attachSync(SyncService sync) => _sync = sync;

  bool get isConfigured => FirebaseConfig.isConfigured && _db != null;

  CollectionReference<Map<String, dynamic>> get _issues =>
      _db!.collection(FirestorePaths.issues);

  Future<List<TrailIssue>> listNearby({
    required double latitude,
    required double longitude,
    double radiusMiles = 25,
  }) async {
    final cached = await _offline.getCachedIssues();

    if (_offline.isOnline && isConfigured) {
      try {
        final snap =
            await _issues.orderBy('created_at', descending: true).get();
        final issues = snap.docs.map(_fromDoc).toList();
        await _offline.cacheIssues(issues);
        return _filterNearby(issues, latitude, longitude, radiusMiles);
      } catch (_) {
        return _filterNearby(cached, latitude, longitude, radiusMiles);
      }
    }

    final demo = DemoStore.instance.issues;
    final byId = <String, TrailIssue>{
      for (final i in cached) i.id: i,
      for (final i in demo) i.id: i,
    };
    return _filterNearby(byId.values.toList(), latitude, longitude, radiusMiles);
  }

  Future<TrailIssue?> getById(String id) async {
    final cached = await _offline.getCachedIssue(id);
    if (cached != null) return cached;

    try {
      return DemoStore.instance.issues.firstWhere((i) => i.id == id);
    } catch (_) {}

    if (!isConfigured || !_offline.isOnline) return null;

    try {
      final doc = await _issues.doc(id).get();
      if (!doc.exists) return null;
      final issue = _fromDoc(doc);
      await _offline.upsertIssue(issue);
      return issue;
    } catch (_) {
      return null;
    }
  }

  Future<TrailIssue> create(TrailIssue issue) async {
    final sync = _sync;
    if (sync != null) return sync.createIssueLocalFirst(issue);

    final store = DemoStore.instance;
    final created = TrailIssue(
      id: store.nextIssueId(),
      issueNumber: store.nextIssueNumber(),
      title: issue.title,
      type: issue.type,
      priority: issue.priority,
      status: IssueStatus.open,
      location: issue.location,
      description: issue.description,
      trailId: issue.trailId,
      trailName: issue.trailName,
      photoUrls: issue.photoUrls,
      estimatedHours: issue.estimatedHours,
      estimatedCrewSize: issue.estimatedCrewSize,
      requiredTools: issue.requiredTools,
      reportedById: store.currentUser?.id,
      reportedByName: store.currentUser?.displayName ?? 'Volunteer',
      agency: issue.agency,
      createdAt: DateTime.now(),
    );
    store.upsertIssue(created);
    await _offline.upsertIssue(created);
    return created;
  }

  Future<TrailIssue> updateStatus(String id, IssueStatus status) async {
    final sync = _sync;
    if (sync != null) return sync.updateStatusLocalFirst(id, status);

    final store = DemoStore.instance;
    final index = store.issues.indexWhere((i) => i.id == id);
    if (index < 0) throw StateError('Issue not found');
    final updated = store.issues[index].copyWith(status: status);
    store.issues[index] = updated;
    await _offline.upsertIssue(updated);
    return updated;
  }

  Future<TrailIssue> addToQueue(String id) async {
    final sync = _sync;
    if (sync != null) return sync.addToQueueLocalFirst(id);

    final store = DemoStore.instance;
    final index = store.issues.indexWhere((i) => i.id == id);
    if (index < 0) throw StateError('Issue not found');
    final updated = store.issues[index].copyWith(inMyQueue: true);
    store.issues[index] = updated;
    await _offline.upsertIssue(updated);
    return updated;
  }

  Future<TrailIssue> acceptIssue(String id) async {
    final sync = _sync;
    if (sync != null) return sync.acceptIssueLocalFirst(id);

    final store = DemoStore.instance;
    final index = store.issues.indexWhere((i) => i.id == id);
    if (index < 0) throw StateError('Issue not found');
    final updated = store.issues[index].copyWith(
      status: IssueStatus.assigned,
      assignedToId: store.currentUser?.id,
      inMyQueue: true,
    );
    store.issues[index] = updated;
    await _offline.upsertIssue(updated);
    return updated;
  }

  Future<List<TrailIssue>> listMyQueue() async {
    final cached = await _offline.getCachedIssues();
    final queued = cached.where((i) => i.inMyQueue).toList();
    if (queued.isNotEmpty || !_offline.isOnline || !isConfigured) {
      return queued.isNotEmpty
          ? queued
          : DemoStore.instance.issues.where((i) => i.inMyQueue).toList();
    }

    final snap = await _db!
        .collection(FirestorePaths.issueQueue)
        .where('in_my_queue', isEqualTo: true)
        .get();
    // Prefer reading from issues cache / docs
    final ids = snap.docs.map((d) => d.data()['issue_id'] as String).toList();
    final results = <TrailIssue>[];
    for (final id in ids) {
      final issue = await getById(id);
      if (issue != null) results.add(issue.copyWith(inMyQueue: true));
    }
    return results;
  }

  /// Used by SyncService when Firebase is configured.
  Future<TrailIssue> pushCreate(TrailIssue issue) async {
    final ref = _issues.doc();
    final data = _toMap(issue)..['id'] = ref.id;
    data['created_at'] = FieldValue.serverTimestamp();
    data['updated_at'] = FieldValue.serverTimestamp();
    // Firestore persists offline and syncs when online.
    await ref.set(data);
    return issue.copyWith(); // id may stay local until remapped by sync
  }

  Future<void> pushStatus(String id, IssueStatus status) async {
    await _issues.doc(id).set({
      'status': status.toDb(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> pushQueue(String issueId, String? userId) async {
    await _db!.collection(FirestorePaths.issueQueue).doc('${userId}_$issueId').set({
      'issue_id': issueId,
      'user_id': userId,
      'in_my_queue': true,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> pushAccept(String id, String? userId) async {
    await _issues.doc(id).set({
      'status': IssueStatus.assigned.toDb(),
      'assigned_to_id': userId,
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  TrailIssue _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    data['id'] = doc.id;
    // Normalize GeoPoint
    final geo = data['location'];
    if (geo is GeoPoint) {
      data['lat'] = geo.latitude;
      data['lng'] = geo.longitude;
    }
    return TrailIssue.fromJson(data);
  }

  Map<String, dynamic> _toMap(TrailIssue issue) {
    final json = issue.toJson();
    json['location'] = GeoPoint(
      issue.location.latitude,
      issue.location.longitude,
    );
    return json;
  }

  List<TrailIssue> _filterNearby(
    List<TrailIssue> issues,
    double lat,
    double lng,
    double radiusMiles,
  ) {
    return issues.where((issue) {
      final miles = _haversineMiles(
        lat,
        lng,
        issue.location.latitude,
        issue.location.longitude,
      );
      return miles <= radiusMiles;
    }).toList()
      ..sort((a, b) {
        final da = _haversineMiles(
            lat, lng, a.location.latitude, a.location.longitude);
        final db = _haversineMiles(
            lat, lng, b.location.latitude, b.location.longitude);
        return da.compareTo(db);
      });
  }

  double _haversineMiles(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusMiles = 3958.8;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;
}
