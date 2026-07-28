import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import 'providers.dart';
import 'router.dart';

class TrailQueueApp extends ConsumerWidget {
  const TrailQueueApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final platform = ref.watch(designKitProvider).platformOverride;

    return MaterialApp.router(
      title: 'Trail Queue',
      theme:
          TrailQueueTheme.build(brightness: Brightness.light, platform: platform),
      darkTheme:
          TrailQueueTheme.build(brightness: Brightness.dark, platform: platform),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
