import 'package:flutter/material.dart';

import '../colors.dart';

/// Metadata badge per DESIGN.md §4 (`MetadataBadge`): a full pill with
/// surface-variant background and subtle icon + text (e.g. "2–4 hrs").
class EffortChip extends StatelessWidget {
  const EffortChip({
    super.key,
    required this.label,
    this.icon = Icons.schedule_outlined,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tokens = TqTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(TqRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Icon(icon, size: 14, color: tokens.textSubtle),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: tokens.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
