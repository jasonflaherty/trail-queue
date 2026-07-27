import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

import 'demo_store.dart';
import 'firebase_config.dart';
import 'firestore_paths.dart';

class NotificationRepository {
  NotificationRepository({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  bool get isConfigured => FirebaseConfig.isConfigured && _db != null;

  Future<List<NotificationItem>> list() async {
    if (!isConfigured) {
      return List<NotificationItem>.from(DemoStore.instance.notifications);
    }

    final snap = await _db!
        .collection(FirestorePaths.notifications)
        .orderBy('created_at', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      return NotificationItem(
        id: d.id,
        kind: NotificationKind.values.firstWhere(
          (k) => k.name == data['kind'],
          orElse: () => NotificationKind.nearbyIssue,
        ),
        title: data['title'] as String? ?? '',
        body: data['body'] as String? ?? '',
        createdAt: (data['created_at'] as Timestamp?)?.toDate() ??
            DateTime.now(),
        read: data['read'] as bool? ?? false,
        relatedId: data['related_id'] as String?,
      );
    }).toList();
  }

  Future<void> markRead(String id) async {
    if (!isConfigured) {
      final list = DemoStore.instance.notifications;
      final i = list.indexWhere((n) => n.id == id);
      if (i >= 0) {
        final n = list[i];
        list[i] = NotificationItem(
          id: n.id,
          kind: n.kind,
          title: n.title,
          body: n.body,
          createdAt: n.createdAt,
          read: true,
          relatedId: n.relatedId,
        );
      }
      return;
    }

    await _db!.collection(FirestorePaths.notifications).doc(id).set({
      'read': true,
    }, SetOptions(merge: true));
  }
}
