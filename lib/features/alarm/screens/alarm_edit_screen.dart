import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sleepy_habbit/features/alarm/providers/alarm_provider.dart';

class AlarmEditScreen extends ConsumerStatefulWidget {
  final String? alarmId;

  const AlarmEditScreen({super.key, this.alarmId});

  @override
  ConsumerState<AlarmEditScreen> createState() => _AlarmEditScreenState();
}

class _AlarmEditScreenState extends ConsumerState<AlarmEditScreen> {
  late TimeOfDay _selectedTime;
  late TextEditingController _labelController;
  late List<bool> _selectedDays; // Mon=0, Sun=6
  int _snoozeDuration = 5;
  int _maxSnoozes = 3;
  bool _vibrate = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = const TimeOfDay(hour: 7, minute: 0);
    _labelController = TextEditingController(text: 'Wake up');
    _selectedDays = [true, true, true, true, true, false, false]; // Mon-Fri
    _isEditing = widget.alarmId != null;
    // TODO: Load existing alarm data if editing
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Alarm' : 'New Alarm'),
        actions: [
          TextButton(
            onPressed: _saveAlarm,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Time Picker
          Center(
            child: InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _selectedTime.format(context),
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Label
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label',
              prefixIcon: Icon(Icons.label_outline),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),

          // Days of week
          Text(
            'Repeat',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _DaySelector(
            selectedDays: _selectedDays,
            onChanged: (days) => setState(() => _selectedDays = days),
            theme: theme,
          ),
          const SizedBox(height: 24),

          // Snooze settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Snooze', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Duration'),
                      DropdownButton<int>(
                        value: _snoozeDuration,
                        items: [1, 3, 5, 10, 15].map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text('$m min'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _snoozeDuration = val!),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Max snoozes'),
                      DropdownButton<int>(
                        value: _maxSnoozes,
                        items: [1, 2, 3, 5, 10].map((m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text('$m'),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _maxSnoozes = val!),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Vibrate toggle
          SwitchListTile(
            title: const Text('Vibrate'),
            value: _vibrate,
            onChanged: (val) => setState(() => _vibrate = val),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  void _saveAlarm() {
    final days = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) days.add(i + 1);
    }

    ref.read(alarmsProvider.notifier).addAlarm(
          label: _labelController.text,
          hour: _selectedTime.hour,
          minute: _selectedTime.minute,
          daysOfWeek: jsonEncode(days),
          snoozeDuration: _snoozeDuration,
          maxSnoozes: _maxSnoozes,
          vibrate: _vibrate,
        );

    context.pop();
  }
}

class _DaySelector extends StatelessWidget {
  final List<bool> selectedDays;
  final Function(List<bool>) onChanged;
  final ThemeData theme;

  const _DaySelector({
    required this.selectedDays,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final isSelected = selectedDays[index];
        return GestureDetector(
          onTap: () {
            final newDays = List<bool>.from(selectedDays);
            newDays[index] = !newDays[index];
            onChanged(newDays);
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Center(
              child: Text(
                labels[index].substring(0, 1),
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
