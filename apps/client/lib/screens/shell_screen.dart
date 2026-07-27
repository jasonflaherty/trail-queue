import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineAsync = ref.watch(isOnlineProvider);
    final pendingAsync = ref.watch(pendingCountProvider);
    final online = onlineAsync.maybeWhen(
      data: (v) => v,
      orElse: () => ref.read(servicesProvider).offline.isOnline,
    );
    final pending = pendingAsync.maybeWhen(data: (v) => v, orElse: () => 0);

    return Scaffold(
      body: Column(
        children: [
          if (!online || pending > 0)
            Material(
              color: online
                  ? TqColors.forestGreen.withValues(alpha: 0.12)
                  : TqColors.priorityMedium.withValues(alpha: 0.18),
              child: SafeArea(
                bottom: false,
                child: InkWell(
                  onTap: () => context.push('/offline'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          online ? Icons.sync : Icons.cloud_off_outlined,
                          size: 18,
                          color: online
                              ? TqColors.forestGreen
                              : TqColors.priorityMedium,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            online
                                ? '$pending change${pending == 1 ? '' : 's'} waiting to sync'
                                : pending > 0
                                    ? 'Offline · $pending queued — tap to sync when online'
                                    : 'Offline · reports still work; tap for details',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: online
                                  ? TqColors.forestGreen
                                  : TqColors.bark,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        current: AppTab.values[navigationShell.currentIndex],
        onChanged: (tab) {
          navigationShell.goBranch(
            tab.index,
            initialLocation: tab.index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
