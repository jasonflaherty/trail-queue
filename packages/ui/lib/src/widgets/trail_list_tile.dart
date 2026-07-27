import 'package:flutter/material.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

import '../colors.dart';

class TrailListTile extends StatelessWidget {
  const TrailListTile({super.key, required this.trail, this.onTap});

  final Trail trail;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      title: Text(trail.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        [
          trail.difficulty.label,
          if (trail.lengthMiles != null)
            '${trail.lengthMiles!.toStringAsFixed(1)} mi',
          if (trail.agency != null) trail.agency!,
        ].join(' • '),
        style: const TextStyle(color: TqColors.slate),
      ),
      trailing: trail.maintenanceGrade != null
          ? Text(trail.maintenanceGrade!.emoji)
          : const Icon(Icons.chevron_right),
    );
  }
}
