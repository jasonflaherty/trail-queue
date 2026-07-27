import 'package:flutter/material.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

/// Bottom sheet listing trails available for import within a selected area.
class ImportTrailsSheet extends StatelessWidget {
  const ImportTrailsSheet({
    super.key,
    required this.trails,
    required this.onImport,
    this.source,
    this.isLoading = false,
  });

  final List<Trail> trails;
  final VoidCallback onImport;
  final ImportSource? source;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: 'Trails in area'),
            Text(
              source != null
                  ? '${trails.length} from ${source!.label}'
                  : '${trails.length} trails found',
              style: const TextStyle(color: TqColors.slate),
            ),
            const SizedBox(height: 8),
            if (trails.isEmpty)
              const EmptyState(
                icon: Icons.terrain_outlined,
                title: 'No trails found',
                message: 'Adjust your selection polygon and try again.',
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: trails.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final trail = trails[index];
                    return TrailListTile(
                      trail: trail,
                      onTap: () {},
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            TqPrimaryButton(
              label: isLoading ? 'Importing…' : 'Import Trails',
              icon: Icons.download_outlined,
              onPressed: isLoading ? null : onImport,
            ),
          ],
        ),
      ),
    );
  }
}
