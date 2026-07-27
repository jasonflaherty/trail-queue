import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trail_queue_models/trail_queue_models.dart';
import 'package:trail_queue_ui/trail_queue_ui.dart';

import '../providers.dart';

/// Routes new users into how they connect with trail stewardship.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  UserRole? _selected;
  bool _loading = false;

  static const _options = <({UserRole role, String title, String body, IconData icon})>[
    (
      role: UserRole.volunteer,
      title: 'Public / Volunteer',
      body:
          'Report trail problems, join crews, and help nonprofits and associations get work done.',
      icon: Icons.hiking,
    ),
    (
      role: UserRole.crewLeader,
      title: 'Crew Leader',
      body: 'Organize volunteer crews, schedule workdays, and assign issues.',
      icon: Icons.groups_outlined,
    ),
    (
      role: UserRole.organization,
      title: 'Nonprofit / Association / Trail Builders',
      body:
          'Publish work, approve volunteers, and coordinate maintenance with the public.',
      icon: Icons.apartment_outlined,
    ),
    (
      role: UserRole.landManager,
      title: 'Land Manager / Agency',
      body: 'Manage official trails, review reports, and partner with steward groups.',
      icon: Icons.account_balance_outlined,
    ),
  ];

  Future<void> _continue() async {
    final role = _selected;
    if (role == null) return;
    setState(() => _loading = true);
    try {
      await ref.read(servicesProvider).auth.completeOnboarding(role);
      if (mounted) context.go('/home');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const BrandMark(),
              const SizedBox(height: 20),
              Text(
                'Who are you connecting as?',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Trail Queue links the public with trail builders, nonprofits, '
                'associations, and land managers so maintenance issues get fixed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: TqColors.slate,
                    ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final selected = _selected == option.role;
                    return Material(
                      color: selected
                          ? TqColors.forestGreen.withValues(alpha: 0.12)
                          : Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setState(() => _selected = option.role),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: selected
                                  ? TqColors.forestGreen
                                  : TqColors.mist,
                              width: selected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(option.icon, color: TqColors.forestGreen),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option.body,
                                      style: const TextStyle(
                                        color: TqColors.slate,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              TqPrimaryButton(
                label: _loading ? 'Saving…' : 'Continue',
                onPressed: _selected == null || _loading ? null : _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
