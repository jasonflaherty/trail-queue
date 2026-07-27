import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:trail_queue_models/trail_queue_models.dart' hide GeoPoint;

import 'demo_store.dart';
import 'firebase_config.dart';
import 'firestore_paths.dart';

/// A steward (org or crew) matched to a new public report.
class RoutedSteward {
  const RoutedSteward({
    required this.id,
    required this.name,
    required this.isCrew,
    this.reason,
  });

  final String id;
  final String name;
  final bool isCrew;
  final String? reason;
}

/// Routes new public issue reports to the trail crews, associations,
/// nonprofits, and land managers responsible for that area, and creates
/// their notifications.
class RoutingService {
  RoutingService({FirebaseFirestore? firestore}) : _db = firestore;

  final FirebaseFirestore? _db;

  bool get isConfigured => FirebaseConfig.isConfigured && _db != null;

  /// Match stewards and write a notification per match.
  /// Returns who was notified so the UI can tell the reporter.
  Future<List<RoutedSteward>> notifyStewards(TrailIssue issue) async {
    final orgs = await _loadOrganizations();
    final crews = await _loadCrews();
    final trails = List<Trail>.from(DemoStore.instance.trails);

    final matched = <RoutedSteward>[];

    // 1. Organizations: match by trail agency, then approved orgs accepting volunteers.
    Trail? trail;
    if (issue.trailId != null) {
      for (final t in trails) {
        if (t.id == issue.trailId) {
          trail = t;
          break;
        }
      }
    }

    for (final org in orgs.where((o) => o.approved)) {
      String? reason;
      if (trail?.agency != null &&
          org.kind == OrganizationKind.landAgency &&
          trail!.agency!.toLowerCase().contains(_firstWord(org.name))) {
        reason = 'Manages ${trail.agency}';
      } else if (org.acceptingVolunteers &&
          org.kind != OrganizationKind.landAgency) {
        reason = 'Active steward group in the area';
      }
      if (reason != null) {
        matched.add(RoutedSteward(
          id: org.id,
          name: org.name,
          isCrew: false,
          reason: reason,
        ));
      }
    }

    // 2. Crews: notify crews (demo: all local crews; Firestore: same, later geo-filtered).
    for (final crew in crews) {
      matched.add(RoutedSteward(
        id: crew.id,
        name: crew.name,
        isCrew: true,
        reason: 'Local trail crew',
      ));
    }

    // Cap noise: highest-value 5 recipients.
    final recipients = matched.take(5).toList();

    for (final steward in recipients) {
      await _createNotification(steward, issue);
    }

    return recipients;
  }

  Future<void> _createNotification(
    RoutedSteward steward,
    TrailIssue issue,
  ) async {
    final title = 'New ${issue.priority.label.toLowerCase()}-priority report';
    final body = issue.trailName != null
        ? '${issue.title} on ${issue.trailName} needs attention.'
        : '${issue.title} was reported near your area.';

    if (!isConfigured) {
      DemoStore.instance.notifications.insert(
        0,
        NotificationItem(
          id: 'n-${DateTime.now().millisecondsSinceEpoch}-${steward.id}',
          kind: NotificationKind.nearbyIssue,
          title: '$title → ${steward.name}',
          body: body,
          createdAt: DateTime.now(),
          relatedId: issue.id,
        ),
      );
      return;
    }

    await _db!.collection(FirestorePaths.notifications).add({
      'kind': NotificationKind.nearbyIssue.name,
      'title': title,
      'body': body,
      'related_id': issue.id,
      'audience_type': steward.isCrew ? 'crew' : 'organization',
      'audience_id': steward.id,
      'read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Organization>> _loadOrganizations() async {
    if (!isConfigured) {
      return List<Organization>.from(DemoStore.instance.organizations);
    }
    final snap = await _db!
        .collection(FirestorePaths.organizations)
        .where('approved', isEqualTo: true)
        .get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return Organization.fromJson(data);
    }).toList();
  }

  Future<List<Crew>> _loadCrews() async {
    if (!isConfigured) {
      return List<Crew>.from(DemoStore.instance.crews);
    }
    final snap =
        await _db!.collection(FirestorePaths.crews).limit(10).get();
    return snap.docs.map((d) {
      final data = d.data();
      data['id'] = d.id;
      return Crew.fromJson(data);
    }).toList();
  }

  String _firstWord(String name) {
    final parts = name.toLowerCase().split(' ');
    return parts.isEmpty ? name.toLowerCase() : parts.first;
  }
}

/// Distance helper exposed for future geo-scoped routing.
double milesBetween(double lat1, double lng1, double lat2, double lng2) {
  const earth = 3958.8;
  final dLat = _rad(lat2 - lat1);
  final dLng = _rad(lng2 - lng1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
  return earth * 2 * atan2(sqrt(a), sqrt(1 - a));
}

double _rad(double d) => d * pi / 180;
