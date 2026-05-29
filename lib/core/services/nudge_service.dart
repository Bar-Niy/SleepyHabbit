import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/database/tables.dart';
import 'package:sleepy_habbit/core/models/user_profile.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';
import 'package:sleepy_habbit/core/services/feature_engineering_service.dart';

/// Proactive nudge types
enum NudgeType {
  reminder, // Gentle reminder (diary time, meal logging)
  insight, // Data-driven observation
  warning, // Pattern-based warning (late meal, caffeine)
  encouragement, // Positive reinforcement (streak, improvement)
}

/// Service that generates context-aware suggestions and nudges
/// based on learned patterns, current time, and user behavior.
class NudgeService {
  final AppDatabase _db;
  final FeatureEngineeringService _features;

  NudgeService(this._db, this._features);

  /// Generate daily nudges. Should be called periodically (e.g., hourly).
  /// Checks conditions and creates nudges if appropriate.
  Future<List<Nudge>> generateNudges() async {
    final existingToday = await _db.nudgeDao.getTodaysNudges();
    if (existingToday.length >= 3) return existingToday; // Max 3 nudges per day

    final profile = await UserProfile.load();
    final recentFeatures = await _features.getRecentFeatures(count: 14);
    final now = DateTime.now();
    final hour = now.hour;

    final newNudges = <NudgesCompanion>[];

    // --- Time-based nudges ---

    // Evening diary reminder (1-2 hours before typical bedtime)
    if (hour >= 20 && hour <= 23) {
      final diaryDoneToday = await _isDiaryDoneToday();
      if (!diaryDoneToday && !_hasNudgeOfType(existingToday, 'reminder')) {
        newNudges.add(_createNudge(
          type: NudgeType.reminder,
          title: 'Time for your evening diary',
          message: 'Offloading your thoughts before bed can help you sleep better. Ready to chat?',
          reason: 'Evening time, diary not completed today',
        ));
      }
    }

    // --- Pattern-based nudges ---

    if (recentFeatures.length >= 7) {
      // Check if caffeine pattern detected
      final caffeineCorrelation = _features.computeBoolCorrelation(
        recentFeatures,
        (f) => f.caffeineAfter2pm,
      );
      if (caffeineCorrelation != null &&
          caffeineCorrelation < -0.25 &&
          hour >= 13 &&
          hour <= 16) {
        if (!_hasNudgeOfType(existingToday, 'warning')) {
          newNudges.add(_createNudge(
            type: NudgeType.warning,
            title: 'Caffeine check',
            message:
                'Your data shows caffeine after 2 PM is linked to worse sleep. '
                'Maybe switch to decaf or water?',
            reason: 'Negative caffeine correlation detected, afternoon time',
          ));
        }
      }

      // Check late meal pattern
      final lateMealCorrelation = _features.computeBoolCorrelation(
        recentFeatures,
        (f) => f.lateMeal,
      );
      if (lateMealCorrelation != null &&
          lateMealCorrelation < -0.25 &&
          hour >= 19 &&
          hour <= 20) {
        if (!_hasNudgeOfType(existingToday, 'warning')) {
          newNudges.add(_createNudge(
            type: NudgeType.warning,
            title: 'Dinner timing',
            message:
                'Eating earlier seems to help your sleep. If you haven\'t eaten yet, '
                'now is a good time before it gets too late!',
            reason: 'Negative late meal correlation, early evening',
          ));
        }
      }

      // Diary completion encouragement
      final diaryRate =
          recentFeatures.where((f) => f.diaryCompleted).length /
              recentFeatures.length;
      final diaryCorrelation = _features.computeBoolCorrelation(
        recentFeatures,
        (f) => f.diaryCompleted,
      );
      if (diaryCorrelation != null &&
          diaryCorrelation > 0.2 &&
          diaryRate < 0.5 &&
          hour >= 19) {
        if (!_hasNudgeOfType(existingToday, 'insight')) {
          newNudges.add(_createNudge(
            type: NudgeType.insight,
            title: 'Diary = better sleep',
            message:
                'On nights you do the diary, your sleep quality averages '
                '${_getDiaryImpact(recentFeatures)} points higher. Worth the 5 minutes!',
            reason: 'Positive diary correlation, low completion rate',
          ));
        }
      }
    }

    // --- Streak / encouragement nudges ---

    if (recentFeatures.length >= 3) {
      // Check for improvement streak
      final last3 = recentFeatures.take(3).toList();
      if (last3.every((f) => f.sleepQuality != null && f.sleepQuality! >= 4)) {
        if (!_hasNudgeOfType(existingToday, 'encouragement')) {
          newNudges.add(_createNudge(
            type: NudgeType.encouragement,
            title: 'Great streak! 🎉',
            message:
                '3 nights of good sleep in a row! Whatever you\'re doing, keep it up.',
            reason: '3-night good sleep streak detected',
          ));
        }
      }

      // Check for declining trend (3 nights getting worse)
      final qualities = last3
          .map((f) => f.sleepQuality)
          .whereType<int>()
          .toList();
      if (qualities.length == 3 &&
          qualities[0] > qualities[1] &&
          qualities[1] > qualities[2]) {
        if (!_hasNudgeOfType(existingToday, 'insight')) {
          newNudges.add(_createNudge(
            type: NudgeType.insight,
            title: 'Sleep dipping',
            message:
                'Your sleep quality has been declining. Let\'s review what changed. '
                'Maybe the evening diary can help uncover what\'s going on.',
            reason: 'Declining sleep quality trend over 3 nights',
          ));
        }
      }
    }

    // --- Weekend vs weekday nudge ---

    if (now.weekday >= 5 && now.weekday <= 6 && hour >= 22) {
      final weekdayFeatures =
          recentFeatures.where((f) => f.isWeekend == false).toList();
      final avgWeekday =
          _averageQuality(weekdayFeatures);
      if (avgWeekday != null && profile.targetSleepHours != null) {
        if (!_hasNudgeOfType(existingToday, 'reminder')) {
          newNudges.add(_createNudge(
            type: NudgeType.reminder,
            title: 'Consistent schedule',
            message:
                'Try to keep a similar bedtime even on weekends. Your body clock '
                'will thank you on Monday morning!',
            reason: 'Weekend night, promoting schedule consistency',
          ));
        }
      }
    }

    // Insert new nudges
    for (final nudge in newNudges) {
      await _db.nudgeDao.insertNudge(nudge);
    }

    return _db.nudgeDao.getTodaysNudges();
  }

  /// Get active (unshown) nudges for display
  Future<List<Nudge>> getActiveNudges() async {
    return _db.nudgeDao.getUnshownNudges();
  }

  /// Mark a nudge as shown
  Future<void> markShown(int id) async {
    await _db.nudgeDao.markShown(id);
  }

  /// Dismiss a nudge
  Future<void> dismiss(int id) async {
    await _db.nudgeDao.markDismissed(id);
  }

  // --- Helpers ---

  NudgesCompanion _createNudge({
    required NudgeType type,
    required String title,
    required String message,
    required String reason,
  }) {
    return NudgesCompanion(
      date: Value(DateTime.now()),
      nudgeType: Value(type.name),
      title: Value(title),
      message: Value(message),
      triggerReason: Value(reason),
    );
  }

  bool _hasNudgeOfType(List<Nudge> nudges, String type) {
    return nudges.any((n) => n.nudgeType == type);
  }

  Future<bool> _isDiaryDoneToday() async {
    final today = DateTime.now();
    final entry = await _db.diaryEntryDao.getEntryForDate(today);
    return entry != null;
  }

  String _getDiaryImpact(List<NightlyFeature> features) {
    final withDiary = features.where((f) => f.diaryCompleted).toList();
    final withoutDiary = features.where((f) => !f.diaryCompleted).toList();
    final avgWith = _averageQuality(withDiary);
    final avgWithout = _averageQuality(withoutDiary);
    if (avgWith != null && avgWithout != null) {
      return (avgWith - avgWithout).toStringAsFixed(1);
    }
    return '0.5';
  }

  double? _averageQuality(List<NightlyFeature> features) {
    final values = features
        .map((f) => f.sleepQuality)
        .whereType<int>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

final nudgeServiceProvider = Provider<NudgeService>((ref) {
  final db = DatabaseService.instance.database;
  final features = ref.read(featureEngineeringProvider);
  return NudgeService(db, features);
});
