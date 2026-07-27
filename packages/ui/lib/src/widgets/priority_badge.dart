import 'package:flutter/material.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

import '../colors.dart';

/// Priority pill per DESIGN.md §4: token colors on a matching container
/// background, and never color-only — always icon + text.
class PriorityBadge extends StatelessWidget {
  const PriorityBadge({super.key, required this.priority, this.compact = false});

  final IssuePriority priority;
  final bool compact;

  IconData get _icon => switch (priority) {
        IssuePriority.low => Icons.arrow_downward_rounded,
        IssuePriority.medium => Icons.drag_handle_rounded,
        IssuePriority.high => Icons.arrow_upward_rounded,
        IssuePriority.critical => Icons.warning_amber_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final tokens = TqTokens.of(context);
    final (fg, bg) = switch (priority) {
      IssuePriority.low => (tokens.priorityLow, tokens.priorityLowBg),
      IssuePriority.medium => (tokens.priorityMed, tokens.priorityMedBg),
      IssuePriority.high => (tokens.priorityHigh, tokens.priorityHighBg),
      IssuePriority.critical => (
          tokens.priorityCritical,
          tokens.priorityCriticalBg
        ),
    };

    return Semantics(
      label: '${priority.label} priority',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(TqRadius.badge),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Icon(_icon, size: compact ? 12 : 14, color: fg),
            ),
            const SizedBox(width: 4),
            Text(
              priority.label,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 11 : 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final IssueStatus status;

  @override
  Widget build(BuildContext context) {
    final tokens = TqTokens.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tokens.surfaceVariant,
        borderRadius: BorderRadius.circular(TqRadius.badge),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
          color: tokens.textBase,
        ),
      ),
    );
  }
}
