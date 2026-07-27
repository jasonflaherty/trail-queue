import 'package:flutter/material.dart';

import '../colors.dart';

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
    return NavigationBar(
      selectedIndex: current.index,
      onDestinationSelected: (i) => onChanged(AppTab.values[i]),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home, color: TqColors.forestGreen),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.map_outlined),
          selectedIcon: Icon(Icons.map, color: TqColors.forestGreen),
          label: 'Map',
        ),
        NavigationDestination(
          icon: Icon(Icons.playlist_add_check_outlined),
          selectedIcon:
              Icon(Icons.playlist_add_check, color: TqColors.forestGreen),
          label: 'My Queue',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups, color: TqColors.forestGreen),
          label: 'Crews',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person, color: TqColors.forestGreen),
          label: 'Profile',
        ),
      ],
    );
  }
}
