import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trail_queue_api/trail_queue_api.dart';
import 'package:trail_queue_map/trail_queue_map.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

final servicesProvider = Provider<AppServices>((ref) => AppServices.instance);

final authUserProvider = StreamProvider<UserProfile?>((ref) {
  final auth = ref.watch(servicesProvider).auth;
  return auth.authStateChanges;
});

final userLocationProvider = FutureProvider<GeoPoint>((ref) async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw StateError('Location disabled');

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Location denied');
    }

    final position = await Geolocator.getCurrentPosition();
    return GeoPoint(position.latitude, position.longitude);
  } catch (_) {
    return GeoPoint(kDefaultMapCenter.latitude, kDefaultMapCenter.longitude);
  }
});

final issuesProvider = FutureProvider<List<TrailIssue>>((ref) async {
  final services = ref.watch(servicesProvider);
  final location = await ref.watch(userLocationProvider.future);
  return services.issues.listNearby(
    latitude: location.latitude,
    longitude: location.longitude,
  );
});

final myQueueProvider = FutureProvider<List<TrailIssue>>((ref) async {
  return ref.watch(servicesProvider).issues.listMyQueue();
});

final trailsProvider = FutureProvider<List<Trail>>((ref) async {
  return ref.watch(servicesProvider).trails.list();
});

final crewsProvider = FutureProvider<List<Crew>>((ref) async {
  return ref.watch(servicesProvider).crews.list();
});

final organizationsProvider = FutureProvider<List<Organization>>((ref) async {
  return ref.watch(servicesProvider).organizations.list();
});

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) async {
  return ref.watch(servicesProvider).notifications.list();
});

final importJobsProvider = FutureProvider<List<ImportJob>>((ref) async {
  return ref.watch(servicesProvider).imports.listJobs();
});

final mapFilterProvider = StateProvider<MapFilter>((ref) => MapFilter.allIssues);

final basemapProvider = StateProvider<BasemapType>((ref) => BasemapType.osm);

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

final polygonPointsProvider = StateProvider<List<GeoPoint>>((ref) => const []);

final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final offline = ref.watch(servicesProvider).offline;
  yield offline.isOnline;
  yield* offline.onlineStream;
});

final pendingMutationsProvider = FutureProvider<List<PendingMutation>>((ref) {
  return ref.watch(servicesProvider).offline.getPendingMutations();
});

final pendingCountProvider = StreamProvider<int>((ref) async* {
  final offline = ref.watch(servicesProvider).offline;
  yield await offline.pendingCount();
  yield* offline.pendingCountStream;
});

final workAreaProvider = FutureProvider<WorkAreaCache?>((ref) {
  return ref.watch(servicesProvider).offline.getWorkArea();
});

final lastSyncedProvider = FutureProvider<DateTime?>((ref) {
  return ref.watch(servicesProvider).offline.lastSyncedAt();
});

void refreshIssueData(WidgetRef ref) {
  ref.invalidate(issuesProvider);
  ref.invalidate(myQueueProvider);
  ref.invalidate(pendingMutationsProvider);
  ref.invalidate(lastSyncedProvider);
}
