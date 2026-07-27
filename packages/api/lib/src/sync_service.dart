import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trail_queue_models/trail_queue_models.dart' hide GeoPoint;

import 'demo_store.dart';
import 'firebase_config.dart';
import 'firestore_paths.dart';
import 'offline_store.dart';

class SyncResult {
  const SyncResult({
    required this.pushed,
    required this.failed,
    required this.pulledIssues,
    this.message,
  });

  final int pushed;
  final int failed;
  final int pulledIssues;
  final String? message;
}

/// Offline-first sync backed by Firestore persistence + Hive mutation queue.
///
/// When Firebase is configured, writes go to Firestore (which queues offline).
/// Hive still caches work areas and pending mutation metadata for the UI.
class SyncService {
  SyncService({
    required OfflineStore offline,
    required Connectivity connectivity,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _offline = offline,
        _connectivity = connectivity,
        _db = firestore,
        _auth = auth;

  final OfflineStore _offline;
  final Connectivity _connectivity;
  final FirebaseFirestore? _db;
  final FirebaseAuth? _auth;

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _syncing = false;

  bool get isConfigured => FirebaseConfig.isConfigured && _db != null;

  Future<void> start() async {
    final initial = await _connectivity.checkConnectivity();
    _offline.setOnline(_hasConnection(initial));
    _sub = _connectivity.onConnectivityChanged.listen((results) async {
      final online = _hasConnection(results);
      _offline.setOnline(online);
      if (online) await syncNow();
    });
    if (_offline.isOnline) await syncNow();
  }

  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<bool> checkOnline() async {
    final results = await _connectivity.checkConnectivity();
    final online = _hasConnection(results);
    _offline.setOnline(online);
    return online;
  }

  Future<TrailIssue> createIssueLocalFirst(TrailIssue issue) async {
    final localId = 'local-${DateTime.now().millisecondsSinceEpoch}';
    final created = TrailIssue(
      id: localId,
      issueNumber: issue.issueNumber ?? Random().nextInt(9000) + 1000,
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
      estimatedDurationLabel: issue.estimatedDurationLabel,
      requiredTools: issue.requiredTools,
      reportedById: issue.reportedById ?? DemoStore.instance.currentUser?.id,
      reportedByName: issue.reportedByName ??
          DemoStore.instance.currentUser?.displayName ??
          'Volunteer',
      agency: issue.agency,
      trailUses: issue.trailUses,
      createdAt: DateTime.now(),
      safetyNotes: issue.safetyNotes,
    );

    await _offline.upsertIssue(created);
    DemoStore.instance.upsertIssue(created);

    // Firestore write — works offline via SDK persistence when configured.
    if (isConfigured) {
      try {
        final remote = await _writeIssueToFirestore(created);
        await _offline.upsertIssue(remote);
        DemoStore.instance.upsertIssue(remote);
        // Remove local-only id if remapped
        if (remote.id != created.id) {
          final cached = await _offline.getCachedIssues();
          await _offline.cacheIssues(
            cached.where((i) => i.id != created.id).toList()..insert(0, remote),
          );
        }
        await _offline.markSyncedNow();
        return remote;
      } catch (_) {
        await _offline.queueMutation(
          PendingMutation(
            id: 'mut-${DateTime.now().millisecondsSinceEpoch}',
            kind: PendingMutationKind.createIssue,
            payload: created.toJson(),
            createdAt: DateTime.now(),
          ),
        );
        return created;
      }
    }

    await _offline.queueMutation(
      PendingMutation(
        id: 'mut-${DateTime.now().millisecondsSinceEpoch}',
        kind: PendingMutationKind.createIssue,
        payload: created.toJson(),
        createdAt: DateTime.now(),
      ),
    );

    if (await checkOnline()) await syncNow();
    return created;
  }

  Future<TrailIssue> updateStatusLocalFirst(
    String id,
    IssueStatus status,
  ) async {
    final existing = await _offline.getCachedIssue(id) ??
        _demoIssue(id);
    if (existing == null) throw StateError('Issue not found offline');

    final updated = existing.copyWith(status: status);
    await _offline.upsertIssue(updated);
    DemoStore.instance.upsertIssue(updated);

    if (isConfigured) {
      try {
        await _db!.collection(FirestorePaths.issues).doc(id).set({
          'status': status.toDb(),
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _offline.markSyncedNow();
        return updated;
      } catch (_) {
        // fall through to queue
      }
    }

    await _offline.queueMutation(
      PendingMutation(
        id: 'mut-${DateTime.now().millisecondsSinceEpoch}',
        kind: PendingMutationKind.updateStatus,
        payload: {'id': id, 'status': status.toDb()},
        createdAt: DateTime.now(),
      ),
    );
    if (await checkOnline()) await syncNow();
    return updated;
  }

  Future<TrailIssue> addToQueueLocalFirst(String id) async {
    final existing = await _offline.getCachedIssue(id) ?? _demoIssue(id);
    if (existing == null) throw StateError('Issue not found offline');
    final updated = existing.copyWith(inMyQueue: true);
    await _offline.upsertIssue(updated);
    DemoStore.instance.upsertIssue(updated);

    if (isConfigured) {
      try {
        final userId = _auth?.currentUser?.uid;
        await _db!
            .collection(FirestorePaths.issueQueue)
            .doc('${userId}_$id')
            .set({
          'issue_id': id,
          'user_id': userId,
          'in_my_queue': true,
          'updated_at': FieldValue.serverTimestamp(),
        });
        await _offline.markSyncedNow();
        return updated;
      } catch (_) {}
    }

    await _offline.queueMutation(
      PendingMutation(
        id: 'mut-${DateTime.now().millisecondsSinceEpoch}',
        kind: PendingMutationKind.addToQueue,
        payload: {'id': id},
        createdAt: DateTime.now(),
      ),
    );
    if (await checkOnline()) await syncNow();
    return updated;
  }

  Future<TrailIssue> acceptIssueLocalFirst(String id) async {
    final existing = await _offline.getCachedIssue(id) ?? _demoIssue(id);
    if (existing == null) throw StateError('Issue not found offline');
    final userId =
        _auth?.currentUser?.uid ?? DemoStore.instance.currentUser?.id;
    final updated = existing.copyWith(
      status: IssueStatus.assigned,
      assignedToId: userId,
      inMyQueue: true,
    );
    await _offline.upsertIssue(updated);
    DemoStore.instance.upsertIssue(updated);

    if (isConfigured) {
      try {
        await _db!.collection(FirestorePaths.issues).doc(id).set({
          'status': IssueStatus.assigned.toDb(),
          'assigned_to_id': userId,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        await _offline.markSyncedNow();
        return updated;
      } catch (_) {}
    }

    await _offline.queueMutation(
      PendingMutation(
        id: 'mut-${DateTime.now().millisecondsSinceEpoch}',
        kind: PendingMutationKind.acceptIssue,
        payload: {'id': id, 'assigned_to_id': userId},
        createdAt: DateTime.now(),
      ),
    );
    if (await checkOnline()) await syncNow();
    return updated;
  }

  Future<WorkAreaCache> downloadWorkArea({
    String label = 'Current work area',
    required double latitude,
    required double longitude,
    double radiusMiles = 15,
  }) async {
    List<TrailIssue> issues;
    List<Trail> trails;
    List<TrailAsset> assets;

    if (await checkOnline() && isConfigured) {
      try {
        final issueSnap = await _db!
            .collection(FirestorePaths.issues)
            .orderBy('created_at', descending: true)
            .get();
        issues = issueSnap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          final geo = data['location'];
          if (geo is GeoPoint) {
            data['lat'] = geo.latitude;
            data['lng'] = geo.longitude;
          }
          return TrailIssue.fromJson(data);
        }).toList();

        final trailSnap = await _db.collection(FirestorePaths.trails).get();
        trails = trailSnap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          return Trail.fromJson(data);
        }).toList();

        final assetSnap = await _db.collection(FirestorePaths.assets).get();
        assets = assetSnap.docs.map((d) {
          final data = d.data();
          data['id'] = d.id;
          final geo = data['location'];
          if (geo is GeoPoint) {
            data['lat'] = geo.latitude;
            data['lng'] = geo.longitude;
          }
          return TrailAsset.fromJson(data);
        }).toList();
      } catch (_) {
        issues = await _offline.getCachedIssues();
        trails = await _offline.getCachedTrails();
        assets = await _offline.getCachedAssets();
      }
    } else {
      issues = List<TrailIssue>.from(DemoStore.instance.issues);
      trails = List<Trail>.from(DemoStore.instance.trails);
      assets = List<TrailAsset>.from(DemoData.assets);
    }

    final filteredIssues = issues.where((i) {
      return _miles(
            latitude,
            longitude,
            i.location.latitude,
            i.location.longitude,
          ) <=
          radiusMiles;
    }).toList();

    return _offline.downloadWorkArea(
      label: label,
      latitude: latitude,
      longitude: longitude,
      radiusMiles: radiusMiles,
      issues: filteredIssues.isEmpty ? issues : filteredIssues,
      trails: trails,
      assets: assets,
    );
  }

  Future<SyncResult> syncNow() async {
    if (_syncing) {
      return const SyncResult(
        pushed: 0,
        failed: 0,
        pulledIssues: 0,
        message: 'Sync already in progress',
      );
    }
    _syncing = true;
    var pushed = 0;
    var failed = 0;
    var pulled = 0;

    try {
      final online = await checkOnline();
      if (!online) {
        return const SyncResult(
          pushed: 0,
          failed: 0,
          pulledIssues: 0,
          message: 'Offline — Firestore will sync when you reconnect',
        );
      }

      final pending = await _offline.getPendingMutations();
      final remaining = <PendingMutation>[];

      for (final mutation in pending) {
        try {
          await _pushMutation(mutation);
          pushed++;
        } catch (e) {
          failed++;
          remaining.add(
            mutation.copyWith(
              attempts: mutation.attempts + 1,
              lastError: e.toString(),
            ),
          );
        }
      }
      await _offline.replacePendingMutations(remaining);

      if (isConfigured) {
        try {
          final snap = await _db!
              .collection(FirestorePaths.issues)
              .orderBy('created_at', descending: true)
              .get();
          final issues = snap.docs.map((d) {
            final data = d.data();
            data['id'] = d.id;
            final geo = data['location'];
            if (geo is GeoPoint) {
              data['lat'] = geo.latitude;
              data['lng'] = geo.longitude;
            }
            return TrailIssue.fromJson(data);
          }).toList();
          final localOnly = (await _offline.getCachedIssues())
              .where((i) => i.id.startsWith('local-'))
              .toList();
          await _offline.cacheIssues([...localOnly, ...issues]);
          pulled = issues.length;
        } catch (_) {}
      } else {
        await _offline.cacheIssues(DemoStore.instance.issues);
        pulled = DemoStore.instance.issues.length;
      }

      await _offline.markSyncedNow();
      return SyncResult(
        pushed: pushed,
        failed: failed,
        pulledIssues: pulled,
        message: failed == 0
            ? (pushed == 0
                ? 'Up to date ($pulled issues)'
                : 'Synced $pushed change${pushed == 1 ? '' : 's'}')
            : 'Synced $pushed, $failed failed — will retry',
      );
    } finally {
      _syncing = false;
    }
  }

  Future<TrailIssue> _writeIssueToFirestore(TrailIssue issue) async {
    final ref = _db!.collection(FirestorePaths.issues).doc();
    final data = issue.toJson()
      ..['id'] = ref.id
      ..['location'] = GeoPoint(
        issue.location.latitude,
        issue.location.longitude,
      )
      ..['created_at'] = FieldValue.serverTimestamp()
      ..['updated_at'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return TrailIssue(
      id: ref.id,
      issueNumber: issue.issueNumber,
      title: issue.title,
      type: issue.type,
      priority: issue.priority,
      status: issue.status,
      location: issue.location,
      description: issue.description,
      trailId: issue.trailId,
      trailName: issue.trailName,
      photoUrls: issue.photoUrls,
      estimatedHours: issue.estimatedHours,
      estimatedCrewSize: issue.estimatedCrewSize,
      estimatedDurationLabel: issue.estimatedDurationLabel,
      requiredTools: issue.requiredTools,
      reportedById: issue.reportedById,
      reportedByName: issue.reportedByName,
      agency: issue.agency,
      trailUses: issue.trailUses,
      createdAt: DateTime.now(),
      safetyNotes: issue.safetyNotes,
      inMyQueue: issue.inMyQueue,
    );
  }

  Future<void> _pushMutation(PendingMutation mutation) async {
    if (!isConfigured) return;

    switch (mutation.kind) {
      case PendingMutationKind.createIssue:
        final issue = TrailIssue.fromJson(mutation.payload);
        final remote = await _writeIssueToFirestore(issue);
        final cached = await _offline.getCachedIssues();
        await _offline.cacheIssues(
          cached.where((i) => i.id != issue.id).toList()..insert(0, remote),
        );
      case PendingMutationKind.updateStatus:
        await _db!.collection(FirestorePaths.issues).doc(
          mutation.payload['id'] as String,
        ).set({
          'status': mutation.payload['status'],
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      case PendingMutationKind.addToQueue:
        final userId = _auth?.currentUser?.uid;
        final issueId = mutation.payload['id'] as String;
        await _db!.collection(FirestorePaths.issueQueue).doc('${userId}_$issueId').set({
          'issue_id': issueId,
          'user_id': userId,
          'in_my_queue': true,
        });
      case PendingMutationKind.acceptIssue:
        await _db!.collection(FirestorePaths.issues).doc(
          mutation.payload['id'] as String,
        ).set({
          'status': IssueStatus.assigned.toDb(),
          'assigned_to_id': mutation.payload['assigned_to_id'],
        }, SetOptions(merge: true));
      case PendingMutationKind.addComment:
        await _db!
            .collection(FirestorePaths.issueComments)
            .add(mutation.payload);
    }
  }

  TrailIssue? _demoIssue(String id) {
    for (final i in DemoStore.instance.issues) {
      if (i.id == id) return i;
    }
    return null;
  }

  double _miles(double lat1, double lng1, double lat2, double lng2) {
    const earth = 3958.8;
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return earth * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _rad(double d) => d * pi / 180;
}
