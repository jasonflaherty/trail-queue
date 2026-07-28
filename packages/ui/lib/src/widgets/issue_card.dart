import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:trail_queue_models/trail_queue_models.dart';

import '../colors.dart';
import 'effort_chip.dart';
import 'priority_badge.dart';

/// Issue list card per DESIGN.md §4: 16px radius, 80x80 thumbnail on the
/// left, title + trail/distance + badge chips. The whole card is one touch
/// target and reads as a single item to screen readers.
class IssueCard extends StatelessWidget {
  const IssueCard({
    super.key,
    required this.issue,
    this.onTap,
  });

  final TrailIssue issue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = TqTokens.of(context);
    final shapes = TqShapes.of(context);
    return Semantics(
      button: onTap != null,
      child: MergeSemantics(
        child: Material(
          color: tokens.surface,
          shape: shapes.cardShape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            customBorder: shapes.cardShape,
            child: Padding(
              padding: const EdgeInsets.all(TqSpacing.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(shapes.card - 2),
                    child: SizedBox(
                      width: 80,
                      height: 80,
                      child: issue.photoUrls.isNotEmpty
                          ? Semantics(
                              image: true,
                              label: 'Photo of ${issue.title}',
                              child: CachedNetworkImage(
                                imageUrl: issue.photoUrls.first,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) =>
                                    _placeholder(tokens),
                              ),
                            )
                          : ExcludeSemantics(child: _placeholder(tokens)),
                    ),
                  ),
                  const SizedBox(width: TqSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: TqSpacing.xs),
                        Text(
                          [
                            if (issue.trailName != null) issue.trailName!,
                            if (issue.distanceMiles != null)
                              '${issue.distanceMiles!.toStringAsFixed(1)} mi away',
                          ].join(' • '),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: tokens.textSubtle,
                                  ),
                        ),
                        const SizedBox(height: TqSpacing.sm),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            PriorityBadge(
                                priority: issue.priority, compact: true),
                            EffortChip(label: issue.timeLabel),
                            EffortChip(
                              label: issue.crewSizeLabel,
                              icon: Icons.groups_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder(TqTokens tokens) {
    return ColoredBox(
      color: tokens.surfaceVariant,
      child: Icon(Icons.terrain, color: tokens.textSubtle),
    );
  }
}
