import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy_habbit/core/models/user_profile.dart';
import 'package:sleepy_habbit/features/onboarding/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (state.currentPage + 1) / 5,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 32),

              // Page content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildPage(state.currentPage, state.profile, notifier, theme),
                ),
              ),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (state.currentPage > 0)
                    TextButton(
                      onPressed: () => notifier.previousPage(),
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox(),
                  ElevatedButton(
                    onPressed: () async {
                      if (state.currentPage < 4) {
                        notifier.nextPage();
                      } else {
                        await notifier.completeOnboarding();
                        if (context.mounted) context.go('/');
                      }
                    },
                    child: Text(state.currentPage < 4 ? 'Next' : 'Get Started'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(int page, UserProfile profile, OnboardingNotifier notifier, ThemeData theme) {
    switch (page) {
      case 0:
        return _WelcomePage(key: const ValueKey(0), theme: theme);
      case 1:
        return _SleepSchedulePage(
          key: const ValueKey(1),
          profile: profile,
          notifier: notifier,
          theme: theme,
        );
      case 2:
        return _SleepIssuesPage(
          key: const ValueKey(2),
          profile: profile,
          notifier: notifier,
          theme: theme,
        );
      case 3:
        return _LifestylePage(
          key: const ValueKey(3),
          profile: profile,
          notifier: notifier,
          theme: theme,
        );
      case 4:
        return _GoalPage(
          key: const ValueKey(4),
          profile: profile,
          notifier: notifier,
          theme: theme,
        );
      default:
        return const SizedBox();
    }
  }
}

class _WelcomePage extends StatelessWidget {
  final ThemeData theme;
  const _WelcomePage({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.nightlight_round,
          size: 80,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to SleepyHabbit',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'I\'m your personal sleep coach. I\'ll help you understand why you sleep the way you do, and how to make it better.\n\nLet me learn a bit about you first.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SleepSchedulePage extends StatelessWidget {
  final UserProfile profile;
  final OnboardingNotifier notifier;
  final ThemeData theme;

  const _SleepSchedulePage({
    super.key,
    required this.profile,
    required this.notifier,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Sleep Schedule',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What does a typical night look like for you?',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),

          // Target sleep hours
          Text('How many hours of sleep do you aim for?',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _ChoiceRow(
            options: ['5-6', '6-7', '7-8', '8-9', '9+'],
            selected: _sleepHoursToString(profile.targetSleepHours),
            onSelected: (val) => notifier.updateProfile(
              profile.copyWith(targetSleepHours: _stringToSleepHours(val)),
            ),
            theme: theme,
          ),
          const SizedBox(height: 24),

          // Typical bedtime
          Text('When do you usually go to bed?',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _ChoiceRow(
            options: ['9 PM', '10 PM', '11 PM', '12 AM', '1+ AM'],
            selected: profile.typicalBedTime,
            onSelected: (val) =>
                notifier.updateProfile(profile.copyWith(typicalBedTime: val)),
            theme: theme,
          ),
          const SizedBox(height: 24),

          // Typical wake time
          Text('When do you usually wake up?',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _ChoiceRow(
            options: ['5 AM', '6 AM', '7 AM', '8 AM', '9+ AM'],
            selected: profile.typicalWakeTime,
            onSelected: (val) =>
                notifier.updateProfile(profile.copyWith(typicalWakeTime: val)),
            theme: theme,
          ),
        ],
      ),
    );
  }

  String? _sleepHoursToString(int? hours) {
    if (hours == null) return null;
    if (hours <= 6) return '5-6';
    if (hours <= 7) return '6-7';
    if (hours <= 8) return '7-8';
    if (hours <= 9) return '8-9';
    return '9+';
  }

  int _stringToSleepHours(String val) {
    switch (val) {
      case '5-6': return 6;
      case '6-7': return 7;
      case '7-8': return 8;
      case '8-9': return 9;
      default: return 9;
    }
  }
}

class _SleepIssuesPage extends StatelessWidget {
  final UserProfile profile;
  final OnboardingNotifier notifier;
  final ThemeData theme;

  const _SleepIssuesPage({
    super.key,
    required this.profile,
    required this.notifier,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sleep Challenges',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What struggles do you face with sleep? (Select all that apply)',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          _MultiSelect(
            options: const {
              'falling_asleep': 'Difficulty falling asleep',
              'staying_asleep': 'Waking up during the night',
              'waking_early': 'Waking up too early',
              'not_rested': 'Not feeling rested after sleep',
              'racing_thoughts': 'Racing thoughts at bedtime',
              'inconsistent': 'Inconsistent schedule',
              'nightmares': 'Bad dreams / nightmares',
              'snoring': 'Snoring / breathing issues',
              'phone_addiction': 'Can\'t put phone down at night',
              'none': 'No major issues - just want to optimize',
            },
            selected: profile.sleepIssues,
            onChanged: (issues) =>
                notifier.updateProfile(profile.copyWith(sleepIssues: issues)),
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _LifestylePage extends StatelessWidget {
  final UserProfile profile;
  final OnboardingNotifier notifier;
  final ThemeData theme;

  const _LifestylePage({
    super.key,
    required this.profile,
    required this.notifier,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lifestyle Context',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help me understand your daily life better.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),

          // Work schedule
          Text('Work schedule:', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _ChoiceRow(
            options: ['Regular 9-5', 'Shift work', 'Freelance', 'Student', 'Other'],
            selected: profile.workSchedule,
            onSelected: (val) =>
                notifier.updateProfile(profile.copyWith(workSchedule: val)),
            theme: theme,
          ),
          const SizedBox(height: 24),

          // Known factors
          Text('What do you think affects your sleep?',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _MultiSelect(
            options: const {
              'caffeine': 'Caffeine',
              'screen_time': 'Screen time',
              'stress': 'Work stress',
              'late_meals': 'Eating late',
              'alcohol': 'Alcohol',
              'exercise': 'Lack of exercise',
              'noise': 'Noise / environment',
              'partner': 'Partner disturbances',
              'anxiety': 'General anxiety',
            },
            selected: profile.knownFactors,
            onChanged: (factors) =>
                notifier.updateProfile(profile.copyWith(knownFactors: factors)),
            theme: theme,
          ),
          const SizedBox(height: 24),

          // Share bed
          SwitchListTile(
            title: const Text('Share bed with partner'),
            value: profile.hasPartner,
            onChanged: (val) =>
                notifier.updateProfile(profile.copyWith(hasPartner: val)),
          ),
          SwitchListTile(
            title: const Text('Pets in bedroom'),
            value: profile.hasPets,
            onChanged: (val) =>
                notifier.updateProfile(profile.copyWith(hasPets: val)),
          ),
        ],
      ),
    );
  }
}

class _GoalPage extends StatefulWidget {
  final UserProfile profile;
  final OnboardingNotifier notifier;
  final ThemeData theme;

  const _GoalPage({
    super.key,
    required this.profile,
    required this.notifier,
    required this.theme,
  });

  @override
  State<_GoalPage> createState() => _GoalPageState();
}

class _GoalPageState extends State<_GoalPage> {
  late TextEditingController _nameController;
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name ?? '');
    _goalController = TextEditingController(text: widget.profile.sleepGoal ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Almost done!',
            style: widget.theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'One last thing so I can personalize your experience.',
            style: widget.theme.textTheme.bodyLarge?.copyWith(
              color: widget.theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'What should I call you?',
              hintText: 'Your name (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
            onChanged: (val) => widget.notifier.updateProfile(
              widget.profile.copyWith(name: val),
            ),
          ),
          const SizedBox(height: 24),

          TextField(
            controller: _goalController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'What\'s your #1 sleep goal?',
              hintText: 'e.g. "Fall asleep faster" or "Stop waking at 3 AM"',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.flag_outlined),
            ),
            onChanged: (val) => widget.notifier.updateProfile(
              widget.profile.copyWith(sleepGoal: val),
            ),
          ),
          const SizedBox(height: 32),

          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: widget.theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Here\'s what I\'ll do',
                        style: widget.theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BulletPoint(text: 'Ask about your sleep each morning', theme: widget.theme),
                  _BulletPoint(text: 'Help you offload thoughts before bed', theme: widget.theme),
                  _BulletPoint(text: 'Track meals that might affect sleep', theme: widget.theme),
                  _BulletPoint(text: 'Find patterns and give you insights', theme: widget.theme),
                  _BulletPoint(text: 'All data stays private on your device', theme: widget.theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Shared widgets ---

class _ChoiceRow extends StatelessWidget {
  final List<String> options;
  final String? selected;
  final Function(String) onSelected;
  final ThemeData theme;

  const _ChoiceRow({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selected == option;
        return ChoiceChip(
          label: Text(option),
          selected: isSelected,
          onSelected: (_) => onSelected(option),
          selectedColor: theme.colorScheme.primary.withOpacity(0.2),
          labelStyle: TextStyle(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

class _MultiSelect extends StatelessWidget {
  final Map<String, String> options;
  final List<String> selected;
  final Function(List<String>) onChanged;
  final ThemeData theme;

  const _MultiSelect({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final isSelected = selected.contains(entry.key);
        return FilterChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (val) {
            final newList = List<String>.from(selected);
            if (val) {
              newList.add(entry.key);
            } else {
              newList.remove(entry.key);
            }
            onChanged(newList);
          },
          selectedColor: theme.colorScheme.primary.withOpacity(0.2),
          checkmarkColor: theme.colorScheme.primary,
        );
      }).toList(),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;
  final ThemeData theme;

  const _BulletPoint({required this.text, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
