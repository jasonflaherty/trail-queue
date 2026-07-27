import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_queue_api/trail_queue_api.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppServices.instance.init(
    firebaseOptions: FirebaseConfig.useFirebase
        ? DefaultFirebaseOptions.currentPlatform
        : null,
  );
  runApp(const ProviderScope(child: TrailQueueApp()));
}
