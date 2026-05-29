import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy_habbit/features/alarm/providers/alarm_provider.dart';

class AlarmScreen extends ConsumerWidget {
  const AlarmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarms = ref.watch(alarmsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/alarms/edit'),
          ),
        ],
      ),
      body: alarms.when(
        data: (alarmList) {
          if (alarmList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_off,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No alarms set',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create your first alarm',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alarmList.length,
            itemBuilder: (context, index) {
              final alarm = alarmList[index];
              return _AlarmCard(
                alarm: alarm,
                theme: theme,
                onToggle: (enabled) {
                  ref.read(alarmsProvider.notifier).toggleAlarm(alarm.id, enabled);
                },
                onTap: () => context.push('/alarms/edit?id=${alarm.id}'),
                onDismiss: () {
                  ref.read(alarmsProvider.notifier).deleteAlarm(alarm.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  final dynamic alarm;
  final ThemeData theme;
  final Function(bool) onToggle;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _AlarmCard({
    required this.alarm,
    required this.theme,
    required this.onToggle,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final hour = alarm.hour;
    final minute = alarm.minute;
    final timeStr =
        '${hour > 12 ? hour - 12 : hour}:${minute.toString().padLeft(2, '0')} ${hour >= 12 ? 'PM' : 'AM'}';

    return Dismissible(
      key: Key('alarm_${alarm.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDismiss(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timeStr,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: alarm.isEnabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        alarm.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _DaysRow(daysJson: alarm.daysOfWeek, theme: theme),
                    ],
                  ),
                ),
                Switch(
                  value: alarm.isEnabled,
                  onChanged: onToggle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DaysRow extends StatelessWidget {
  final String daysJson;
  final ThemeData theme;

  const _DaysRow({required this.daysJson, required this.theme});

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // Parse days from JSON string like [1,2,3,4,5]
    final activeDays = <int>[];
    try {
      final cleaned = daysJson.replaceAll('[', '').replaceAll(']', '');
      for (final s in cleaned.split(',')) {
        final trimmed = s.trim();
        if (trimmed.isNotEmpty) activeDays.add(int.parse(trimmed));
      }
    } catch (_) {}

    return Row(
      children: List.generate(7, (index) {
        final isActive = activeDays.contains(index + 1);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(
            dayLabels[index],
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        );
      }),
    );
  }
}
