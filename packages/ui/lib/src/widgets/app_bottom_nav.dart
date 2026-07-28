import 'package:flutter/material.dart';

import '../colors.dart';
import 'glass_surface.dart';

enum AppTab { home, map, myQueue, crews, profile }

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.current,
    required this.onChanged,
  });

  final AppTab current;
  final ValueChanged<AppTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = TqTokens.of(context);
    final platform = Theme.of(context).platform;
    final isApple = platform == TargetPlatform.iOS ||
        platform == TargetPlatform.macOS;

    final bar = NavigationBar(
      selectedIndex: current.index,
      onDestinationSelected: (i) => onChanged(AppTab.values[i]),
      backgroundColor: isApple ? Colors.transparent : null,
      destinations: [
        NavigationDestination(
          icon: const Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: tokens.primary),
          label: 'Home',
        ),
        NavigationDestination(
          icon: const Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map, color: tokens.primary),
          label: 'Map',
        ),
        NavigationDestination(
          icon: const Icon(Icons.playlist_add_check_outlined),
          selectedIcon:
              Icon(Icons.playlist_add_check, color: tokens.primary),
          label: 'My Queue',
        ),
        NavigationDestination(
          icon: const Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups, color: tokens.primary),
          label: 'Crews',
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: tokens.primary),
          label: 'Profile',
        ),
      ],
    );

    // iOS 26: frosted glass tab bar; Android: opaque M3 navigation bar.
    return isApple ? TqGlassSurface(child: bar) : bar;
  }
}
