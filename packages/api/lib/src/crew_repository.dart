import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

import 'demo_store.dart';
import 'firebase_config.dart';
import 'firestore_paths.dart';

class CrewRepository {
  CrewRepository({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  bool get isConfigured => FirebaseConfig.isConfigured && _db != null;

  Future<List<Crew>> list() async {
    if (!isConfigured) return List<Crew>.from(DemoStore.instance.crews);

    final snap = await _db!.collection(FirestorePaths.crews).orderBy('name').get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return Crew.fromJson(data);
    }).toList();
  }

  Future<Crew?> getById(String id) async {
    final crews = await list();
    try {
      return crews.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Crew> create(Crew crew) async {
    if (!isConfigured) {
      final created = Crew(
        id: 'crew-${DateTime.now().millisecondsSinceEpoch}',
        name: crew.name,
        description: crew.description,
        leaderId: crew.leaderId,
        leaderName: crew.leaderName,
        memberCount: 1,
        organizationId: crew.organizationId,
      );
      DemoStore.instance.crews.add(created);
      return created;
    }

    final ref = _db!.collection(FirestorePaths.crews).doc();
    final data = {
      'name': crew.name,
      'description': crew.description,
      'leader_id': crew.leaderId,
      'leader_name': crew.leaderName,
      'member_count': 1,
      'organization_id': crew.organizationId,
      'created_at': FieldValue.serverTimestamp(),
    };
    await ref.set(data);
    return Crew(
      id: ref.id,
      name: crew.name,
      description: crew.description,
      leaderId: crew.leaderId,
      leaderName: crew.leaderName,
      memberCount: 1,
      organizationId: crew.organizationId,
    );
  }

  Future<CrewInvitation> invite({
    required String crewId,
    required String crewName,
    required String email,
  }) async {
    if (!isConfigured) {
      return CrewInvitation(
        id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
        crewId: crewId,
        crewName: crewName,
        email: email,
      );
    }

    final ref = _db!.collection(FirestorePaths.crewInvitations).doc();
    await ref.set({
      'crew_id': crewId,
      'crew_name': crewName,
      'email': email,
      'status': 'pending',
      'created_at': FieldValue.serverTimestamp(),
    });
    return CrewInvitation(
      id: ref.id,
      crewId: crewId,
      crewName: crewName,
      email: email,
    );
  }
}
