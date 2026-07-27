import 'package:flutter/material.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

import '../colors.dart';

/// Grid of issue types supporting a primary selection plus optional
/// secondary (additional condition) selections.
///
/// When [secondary] / [onSecondaryChanged] are not used, it behaves as a
/// simple single-select grid.
class IssueTypeGrid extends StatelessWidget {
  const IssueTypeGrid({
    super.key,
    required this.selected,
    required this.onSelected,
    this.secondary = const <IssueType>{},
    this.types = IssueType.reportGrid,
  });

  /// Primary issue type.
  final IssueType? selected;

  /// Additional conditions.
  final Set<IssueType> secondary;

  final ValueChanged<IssueType> onSelected;
  final List<IssueType> types;

  IconData _iconFor(IssueType type) => switch (type) {
        IssueType.blowdown => Icons.park_outlined,
        IssueType.erosion => Icons.landscape_outlined,
        IssueType.washout => Icons.water_outlined,
        IssueType.bridgeDamage ||
        IssueType.missingBridgePlank =>
          Icons.foundation_outlined,
        IssueType.missingSign || IssueType.brokenSign => Icons.campaign_outlined,
        IssueType.drainageBlocked => Icons.water_drop_outlined,
        IssueType.rockSlide => Icons.terrain_outlined,
        _ => Icons.more_horiz,
      };

  @override
  Widget build(BuildContext context) {
    final tokens = TqTokens.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: types.length,
      // Tiles stay comfortably above the 48px minimum touch target and keep
      // >= 8px gaps between adjacent targets (DESIGN.md §2).
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemBuilder: (context, index) {
        final type = types[index];
        final isPrimary = selected == type;
        final isSecondary = secondary.contains(type);
        final isSelected = isPrimary || isSecondary;

        final accent = isPrimary ? tokens.primary : tokens.textSubtle;
        return Semantics(
          button: true,
          selected: isSelected,
          label: isPrimary
              ? '${type.label}, primary issue'
              : isSecondary
                  ? '${type.label}, additional condition'
                  : type.label,
          child: InkWell(
            onTap: () => onSelected(type),
            borderRadius: BorderRadius.circular(TqRadius.card),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? tokens.primary.withValues(alpha: 0.15)
                        : isSecondary
                            ? tokens.textSubtle.withValues(alpha: 0.12)
                            : tokens.surface,
                    borderRadius: BorderRadius.circular(TqRadius.card),
                    border: Border.all(
                      color: isSelected
                          ? accent
                          : tokens.textSubtle.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(TqSpacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _iconFor(type),
                        color: isSelected ? accent : tokens.textSubtle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        type.gridLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? accent : tokens.textBase,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: ExcludeSemantics(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius:
                              BorderRadius.circular(TqRadius.badge),
                        ),
                        child: Text(
                          isPrimary ? '1st' : '+',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: tokens.primaryOn,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
