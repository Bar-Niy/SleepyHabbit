import 'dart:io';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';
import 'package:sleepy_habbit/core/services/llm_service.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

class MealCaptureScreen extends ConsumerStatefulWidget {
  const MealCaptureScreen({super.key});

  @override
  ConsumerState<MealCaptureScreen> createState() => _MealCaptureScreenState();
}

class _MealCaptureScreenState extends ConsumerState<MealCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;
  String _selectedMealType = 'lunch';
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSaving = false;
  String? _llmFeedback;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Meal'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo section
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.outline.withOpacity(0.3),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
                  image: _imageFile != null
                      ? DecorationImage(
                          image: FileImage(_imageFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _imageFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to take a photo',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.4),
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),

            // Meal type selector
            Text(
              'Meal Type',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'breakfast', label: Text('Brkfst')),
                ButtonSegment(value: 'lunch', label: Text('Lunch')),
                ButtonSegment(value: 'dinner', label: Text('Dinner')),
                ButtonSegment(value: 'snack', label: Text('Snack')),
              ],
              selected: {_selectedMealType},
              onSelectionChanged: (selection) {
                setState(() => _selectedMealType = selection.first);
              },
            ),
            const SizedBox(height: 20),

            // Description
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'What did you eat?',
                hintText: 'Describe your meal (optional if photo taken)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),

            // LLM feedback
            if (_llmFeedback != null) ...[
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb,
                            size: 20,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sleep Coach Says',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _llmFeedback!,
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Save button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveMeal,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Saving...' : 'Save Meal'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveMeal() async {
    setState(() => _isSaving = true);

    try {
      final llm = ref.read(llmServiceProvider);

      // Get LLM analysis on how this meal might affect sleep
      final description = _descriptionController.text.isNotEmpty
          ? _descriptionController.text
          : 'A $_selectedMealType meal';

      final hour = DateTime.now().hour;
      final analysis = await llm.chat(messages: [
        {
          'role': 'system',
          'content':
              'You are a sleep-focused nutritionist. Given a meal description and time, briefly comment on how it might affect sleep quality. Keep response to 1-2 sentences.'
        },
        {
          'role': 'user',
          'content':
              'I had this for $_selectedMealType at ${hour}:00 - $description'
        },
      ]);

      setState(() => _llmFeedback = analysis);

      // Save to database
      final db = DatabaseService.instance.database;
      await db.mealEntryDao.insertEntry(
        MealEntriesCompanion(
          date: Value(DateTime.now()),
          mealType: Value(_selectedMealType),
          photoPath: Value(_imageFile?.path),
          description: Value(description),
          llmAnalysis: Value(analysis),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Meal saved!')),
        );
        // Wait a moment so user can see feedback
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving meal: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
