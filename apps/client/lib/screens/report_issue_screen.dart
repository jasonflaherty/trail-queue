import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_api/trail_queue_api.dart';
import 'package:trail_queue_map/trail_queue_map.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  IssueType? _selectedType;
  final _secondaryTypes = <IssueType>{};
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  GeoPoint? _location;
  final _photoUrls = <String>[];
  bool _submitting = false;

  static const _demoPhotos = [
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800',
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=800',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _useMyLocation() async {
    final location = await ref.read(userLocationProvider.future);
    setState(() => _location = location);
  }

  void _toggleType(IssueType type) {
    setState(() {
      if (_selectedType == type) {
        // Deselect primary; promote the first secondary if there is one.
        if (_secondaryTypes.isNotEmpty) {
          _selectedType = _secondaryTypes.first;
          _secondaryTypes.remove(_selectedType);
        } else {
          _selectedType = null;
        }
      } else if (_secondaryTypes.contains(type)) {
        _secondaryTypes.remove(type);
      } else if (_selectedType == null) {
        _selectedType = type;
      } else {
        _secondaryTypes.add(type);
      }
    });
  }

  void _addDemoPhoto() {
    final next = _demoPhotos[_photoUrls.length % _demoPhotos.length];
    setState(() => _photoUrls.add(next));
  }

  Future<void> _classifyIfNeeded() async {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedType != null) return;
    final suggestion = await ref.read(servicesProvider).ai.classifyIssue(
          title: title,
          description: _detailsController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _selectedType = suggestion.type);
  }

  Future<void> _submit() async {
    final type = _selectedType;
    final title = _titleController.text.trim();
    if (type == null || title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a type and enter a title')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final location = _location ??
          GeoPoint(kDefaultMapCenter.latitude, kDefaultMapCenter.longitude);
      final suggestion = await ref.read(servicesProvider).ai.classifyIssue(
            title: title,
            description: _detailsController.text.trim(),
          );

      final services = ref.read(servicesProvider);
      final created = await services.issues.create(
        TrailIssue(
          id: '',
          title: title,
          type: type,
          secondaryTypes: _secondaryTypes.toList(),
          priority: suggestion.priority,
          status: IssueStatus.open,
          location: location,
          description: _detailsController.text.trim(),
          photoUrls: _photoUrls,
          estimatedHours: suggestion.estimatedHours,
          estimatedCrewSize: suggestion.crewSize,
          requiredTools: suggestion.requiredTools,
        ),
      );

      // Route the report to responsible crews and organizations.
      List<RoutedSteward> notified = const [];
      try {
        notified = await services.routing.notifyStewards(created);
      } catch (_) {
        // Notification routing is best-effort; the report itself is saved.
      }

      refreshIssueData(ref);
      ref.invalidate(notificationsProvider);

      if (mounted) {
        if (notified.isNotEmpty) {
          final names = notified.take(3).map((s) => s.name).join(', ');
          final extra =
              notified.length > 3 ? ' +${notified.length - 3} more' : '';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              duration: const Duration(seconds: 5),
              content: Text('Report sent — notified $names$extra'),
            ),
          );
        }
        context.go('/issues/${created.id}');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool get _hasUnsavedWork =>
      _photoUrls.isNotEmpty || _location != null || _selectedType != null;

  Future<void> _confirmDiscard(bool didPop, Object? result) async {
    if (didPop || _submitting) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this report?'),
        content: const Text(
          'Your photos, location, and selections will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedWork,
      onPopInvokedWithResult: _confirmDiscard,
      child: _buildScaffold(context),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Issue')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: 'What needs work?'),
          const SizedBox(height: 4),
          Text(
            'Tap the main problem first, then add any other conditions.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          IssueTypeGrid(
            selected: _selectedType,
            secondary: _secondaryTypes,
            onSelected: _toggleType,
          ),
          if (_secondaryTypes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Primary: ${_selectedType?.label ?? '—'}   •   '
              'Also: ${_secondaryTypes.map((t) => t.label).join(', ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 24),
          const SectionHeader(title: 'Location'),
          const SizedBox(height: 8),
          TqOutlineButton(
            label: _location == null
                ? 'Use My Location'
                : 'Location: ${_location!.display}',
            icon: Icons.my_location,
            onPressed: _useMyLocation,
          ),
          const SizedBox(height: 24),
          const SectionHeader(title: 'Photos'),
          const SizedBox(height: 8),
          PhotoUploader(
            urls: _photoUrls,
            onAdd: _addDemoPhoto,
            onRemove: (index) => setState(() => _photoUrls.removeAt(index)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
            onEditingComplete: _classifyIfNeeded,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _detailsController,
            decoration: const InputDecoration(labelText: 'Details'),
            maxLines: 4,
          ),
          const SizedBox(height: 24),
          TqPrimaryButton(
            label: _submitting ? 'Submitting…' : 'Submit Report',
            icon: Icons.check,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
