import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/database/tables.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';
import 'package:sleepy_habbit/core/services/feature_engineering_service.dart';
import 'package:sleepy_habbit/core/services/llm_service.dart';

/// Generates weekly mini-reports after 7+ days of data.
/// Summarizes trends, finds correlations, and generates actionable insights.
class WeeklyReportService {
  final AppDatabase _db;
  final FeatureEngineeringService _features;
  final LlmService _llm;

  WeeklyReportService(this._db, this._features, this._llm);

  /// Generate a report for the past week.
  /// Returns the generated report or null if insufficient data.
  Future<WeeklyReport?> generateWeeklyReport({DateTime? weekEnd}) async {
    final end = weekEnd ?? DateTime.now();
    final start = end.subtract(const Duration(days: 7));

    // Get nightly features for the week
    final features = await _features.getFeaturesInRange(start, end);
    if (features.length < 3) return null; // Need at least 3 days of data

    // Compute averages
    final avgQuality = _average(features, (f) => f.sleepQuality?.toDouble());
    final avgMood = _average(features, (f) => f.moodMorning?.toDouble());
    final avgDuration = _average(features, (f) => f.sleepDurationHours);
    final avgStress = _average(features, (f) => f.stressLevel?.toDouble());
    final daysWithDiary = features.where((f) => f.diaryCompleted).length;

    // Get top correlations
    final correlations = await _features.getTopCorrelations(days: 14);
    final correlationJson = jsonEncode(
      correlations.map((c) => c.toJson()).toList(),
    );

    // Generate LLM narrative
    final narrative = await _generateNarrative(
      features: features,
      avgQuality: avgQuality,
      avgMood: avgMood,
      avgDuration: avgDuration,
      correlations: correlations,
      daysWithDiary: daysWithDiary,
    );

    // Generate recommendations
    final recommendations = await _generateRecommendations(
      features: features,
      correlations: correlations,
    );

    // Store report
    final reportId = await _db.weeklyReportDao.insertReport(
      WeeklyReportsCompanion(
        weekStart: Value(start),
        weekEnd: Value(end),
        avgSleepQuality: Value(avgQuality),
        avgMoodMorning: Value(avgMood),
        avgSleepDuration: Value(avgDuration),
        avgStressLevel: Value(avgStress),
        daysWithDiary: Value(daysWithDiary),
        totalNights: Value(features.length),
        topCorrelations: Value(correlationJson),
        llmNarrative: Value(narrative),
        recommendations: Value(recommendations),
      ),
    );

    return _db.weeklyReportDao.getReportForWeek(start);
  }

  Future<String> _generateNarrative({
    required List<NightlyFeature> features,
    required double? avgQuality,
    required double? avgMood,
    required double? avgDuration,
    required List<FeatureCorrelation> correlations,
    required int daysWithDiary,
  }) async {
    // Build a data summary for the LLM
    final dataSummary = StringBuffer();
    dataSummary.writeln('WEEKLY SLEEP DATA (${features.length} nights):');
    dataSummary.writeln('- Average sleep quality: ${avgQuality?.toStringAsFixed(1) ?? "N/A"}/5');
    dataSummary.writeln('- Average morning mood: ${avgMood?.toStringAsFixed(1) ?? "N/A"}/5');
    dataSummary.writeln('- Average sleep duration: ${avgDuration?.toStringAsFixed(1) ?? "N/A"} hours');
    dataSummary.writeln('- Days with evening diary: $daysWithDiary/${features.length}');
    dataSummary.writeln('');

    // Night-by-night details
    dataSummary.writeln('NIGHTLY BREAKDOWN:');
    for (final f in features) {
      final dow = _dayName(f.dayOfWeek ?? 0);
      dataSummary.write('$dow: quality=${f.sleepQuality ?? "?"}');
      if (f.diaryCompleted) dataSummary.write(', diary=yes');
      if (f.caffeineAfter2pm == true) dataSummary.write(', caffeine=yes');
      if (f.lateMeal == true) dataSummary.write(', late_meal=yes');
      if (f.hadAlcohol == true) dataSummary.write(', alcohol=yes');
      if (f.moodEvening != null) dataSummary.write(', evening_mood=${f.moodEvening}');
      dataSummary.writeln();
    }

    if (correlations.isNotEmpty) {
      dataSummary.writeln('');
      dataSummary.writeln('CORRELATIONS FOUND:');
      for (final c in correlations.take(5)) {
        dataSummary.writeln('- ${c.interpretation} (r=${c.correlation.toStringAsFixed(2)})');
      }
    }

    return _llm.chat(
      messages: [
        {
          'role': 'system',
          'content': '''You are a sleep coach writing a personalized weekly report.
Based on the data below, write a warm, encouraging, and insightful 3-4 paragraph summary.
Include:
1. How the week went overall (celebrate wins, acknowledge challenges)
2. Key patterns observed (connect specific behaviors to sleep outcomes)
3. One specific, actionable suggestion for next week

Keep the tone like a supportive friend who happens to be a sleep scientist.
Don't use medical jargon. Be specific to THEIR data.'''
        },
        {'role': 'user', 'content': dataSummary.toString()},
      ],
      maxTokens: 600,
      temperature: 0.7,
    );
  }

  Future<String> _generateRecommendations({
    required List<NightlyFeature> features,
    required List<FeatureCorrelation> correlations,
  }) async {
    // Generate targeted recommendations based on patterns
    final recommendations = <String>[];

    // Check diary completion rate
    final diaryRate =
        features.where((f) => f.diaryCompleted).length / features.length;
    if (diaryRate < 0.5) {
      recommendations.add(
          'Try to complete the evening diary more often — your sleep quality tends to be better on diary nights.');
    }

    // Check for caffeine correlation
    final caffeineNights =
        features.where((f) => f.caffeineAfter2pm == true).toList();
    final noCaffeineNights =
        features.where((f) => f.caffeineAfter2pm == false).toList();
    if (caffeineNights.isNotEmpty && noCaffeineNights.isNotEmpty) {
      final caffeineAvg =
          _average(caffeineNights, (f) => f.sleepQuality?.toDouble());
      final noCaffeineAvg =
          _average(noCaffeineNights, (f) => f.sleepQuality?.toDouble());
      if (caffeineAvg != null && noCaffeineAvg != null && noCaffeineAvg - caffeineAvg > 0.5) {
        recommendations.add(
            'Cutting caffeine after 2 PM improved your sleep by ${(noCaffeineAvg - caffeineAvg).toStringAsFixed(1)} points on average.');
      }
    }

    // Check late meals
    final lateMealNights =
        features.where((f) => f.lateMeal == true).toList();
    final earlyMealNights =
        features.where((f) => f.lateMeal == false).toList();
    if (lateMealNights.isNotEmpty && earlyMealNights.isNotEmpty) {
      final lateAvg =
          _average(lateMealNights, (f) => f.sleepQuality?.toDouble());
      final earlyAvg =
          _average(earlyMealNights, (f) => f.sleepQuality?.toDouble());
      if (lateAvg != null && earlyAvg != null && earlyAvg - lateAvg > 0.5) {
        recommendations.add(
            'Eating dinner earlier (before 8 PM) is associated with better sleep for you.');
      }
    }

    // Add correlation-based recommendations
    for (final c in correlations.take(3)) {
      if (c.correlation > 0.3) {
        recommendations
            .add('Keep it up: ${c.featureName} is positively linked to your sleep quality.');
      } else if (c.correlation < -0.3) {
        recommendations.add(
            'Watch out: ${c.featureName} seems to negatively affect your sleep.');
      }
    }

    return jsonEncode(recommendations);
  }

  double? _average(
    List<NightlyFeature> features,
    double? Function(NightlyFeature) extractor,
  ) {
    final values = features.map(extractor).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _dayName(int dow) {
    const names = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (dow >= 1 && dow <= 7) return names[dow];
    return '?';
  }

  /// Check if a weekly report should be generated (every Sunday or after 7 days)
  Future<bool> shouldGenerateReport() async {
    final lastReport = await _db.weeklyReportDao.getLatestReport();
    if (lastReport == null) {
      // Check if we have enough data
      final features = await _features.getRecentFeatures(count: 7);
      return features.length >= 3;
    }
    return DateTime.now().difference(lastReport.weekEnd).inDays >= 7;
  }
}

final weeklyReportServiceProvider = Provider<WeeklyReportService>((ref) {
  final db = DatabaseService.instance.database;
  final features = ref.read(featureEngineeringProvider);
  final llm = ref.read(llmServiceProvider);
  return WeeklyReportService(db, features, llm);
});
