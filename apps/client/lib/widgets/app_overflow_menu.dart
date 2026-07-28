import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Three-dot overflow menu shown on the main tab screens.
class AppOverflowMenu extends StatelessWidget {
  const AppOverflowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More options',
      icon: const Icon(Icons.more_vert),
      onSelected: (route) => context.push(route),
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: '/settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        PopupMenuItem(
          value: '/notifications',
          child: ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('Notifications'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        PopupMenuItem(
          value: '/offline',
          child: ListTile(
            leading: Icon(Icons.download_for_offline_outlined),
            title: Text('Offline & Sync'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}
