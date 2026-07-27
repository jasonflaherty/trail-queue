/// Firebase configuration for Trail Queue.
///
/// Enable with:
/// ```bash
/// flutter run --dart-define=USE_FIREBASE=true
/// ```
///
/// Then run `flutterfire configure` to generate real [DefaultFirebaseOptions]
/// in `apps/client/lib/firebase_options.dart`.
class FirebaseConfig {
  FirebaseConfig._();

  /// Set via `--dart-define=USE_FIREBASE=true` after FlutterFire setup.
  static const bool useFirebase =
      bool.fromEnvironment('USE_FIREBASE', defaultValue: false);

  /// True when the app should talk to Firebase (Auth + Firestore + Storage).
  static bool get isConfigured => useFirebase && _initialized;

  static bool _initialized = false;

  static void markInitialized() => _initialized = true;

  static void markNotInitialized() => _initialized = false;
}
