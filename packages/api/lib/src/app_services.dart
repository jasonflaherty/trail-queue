import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'ai_repository.dart';
import 'asset_repository.dart';
import 'auth_repository.dart';
import 'crew_repository.dart';
import 'firebase_config.dart';
import 'import_repository.dart';
import 'issue_repository.dart';
import 'notification_repository.dart';
import 'offline_store.dart';
import 'organization_repository.dart';
import 'routing_service.dart';
import 'score_service.dart';
import 'sync_service.dart';
import 'trail_repository.dart';

typedef FirebaseOptionsProvider = FirebaseOptions Function();

class AppServices {
  AppServices._();

  static final AppServices instance = AppServices._();

  late final AuthRepository auth;
  late final IssueRepository issues;
  late final TrailRepository trails;
  late final AssetRepository assets;
  late final CrewRepository crews;
  late final OrganizationRepository organizations;
  late final ImportRepository imports;
  late final AiRepository ai;
  late final NotificationRepository notifications;
  late final RoutingService routing;
  late final OfflineStore offline;
  late final SyncService sync;
  late final ScoreService scores;
  late final Connectivity connectivity;

  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isOnlineConfigured => FirebaseConfig.isConfigured;

  /// Optional: pass [firebaseOptions] from `DefaultFirebaseOptions.currentPlatform`
  /// when running with `--dart-define=USE_FIREBASE=true`.
  Future<void> init({FirebaseOptions? firebaseOptions}) async {
    if (_initialized) return;

    offline = OfflineStore.instance;
    await offline.init();

    FirebaseAuth? authClient;
    FirebaseFirestore? firestore;

    if (FirebaseConfig.useFirebase) {
      try {
        if (Firebase.apps.isEmpty) {
          if (firebaseOptions != null) {
            await Firebase.initializeApp(options: firebaseOptions);
          } else {
            await Firebase.initializeApp();
          }
        }
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        authClient = FirebaseAuth.instance;
        firestore = FirebaseFirestore.instance;
        FirebaseConfig.markInitialized();
      } catch (_) {
        // Fall back to demo mode if Firebase isn't configured on device.
        FirebaseConfig.markNotInitialized();
      }
    }

    connectivity = Connectivity();
    sync = SyncService(
      offline: offline,
      connectivity: connectivity,
      firestore: firestore,
      auth: authClient,
    );

    auth = AuthRepository(auth: authClient, firestore: firestore);
    issues = IssueRepository(
      firestore: firestore,
      offlineStore: offline,
      sync: sync,
    );
    trails = TrailRepository(firestore: firestore, offlineStore: offline);
    assets = AssetRepository(firestore: firestore);
    crews = CrewRepository(firestore: firestore);
    organizations = OrganizationRepository(firestore: firestore);
    imports = ImportRepository(firestore: firestore);
    ai = AiRepository();
    notifications = NotificationRepository(firestore: firestore);
    routing = RoutingService(firestore: firestore);
    scores = ScoreService();

    auth.emitCurrentUser();
    await sync.start();
    _initialized = true;
  }
}
