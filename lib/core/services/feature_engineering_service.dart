import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/models/extracted_data.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

/// Service that computes per-night feature vectors from raw data.
/// Should run after each morning interview completes (and can be re-run
/// retroactively over historical data).
class FeatureEngineeringService {
  final AppDatabase _db;

  FeatureEngineeringService(this._db);

  /// Compute features for a specific date (the morning-of date).
  /// Gathers: morning interview data, previous evening diary, day's meals.
  Future<void> computeFeaturesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    // Previous evening = the night before (diary entry from yesterday evening)
    final previousDay = startOfDay.subtract(const Duration(days: 1));
    final previousDayEnd = startOfDay;

    // 1. Get sleep entry for this morning
    final sleepEntry = await _db.sleepEntryDao.getEntryForDate(date);

    // 2. Get diary entry from previous evening
    final diaryEntry = await _db.diaryEntryDao.getEntryForDate(previousDay);

    // 3. Get meals from previous day
    final meals = await _db.mealEntryDao.getMealsForDate(previousDay);

    // Parse extracted data from sleep entry tags
    SleepExtractionData? sleepExtraction;
    if (sleepEntry?.tags != null) {
      try {
        final json = jsonDecode(sleepEntry!.tags!) as Map<String, dynamic>;
        sleepExtraction = SleepExtractionData.fromJson(json);
      } catch (_) {}
    }

    // Parse meal extractions
    final mealExtractions = <MealExtractionData>[];
    for (final meal in meals) {
      if (meal.extractedData != null) {
        try {
          final json = jsonDecode(meal.extractedData!) as Map<String, dynamic>;
          mealExtractions.add(MealExtractionData.fromJson(json));
        } catch (_) {}
      }
    }

    // Compute meal-level aggregates
    final hasCaffeineInMeals =
        mealExtractions.any((m) => m.containsCaffeine == true);
    final hasAlcoholInMeals =
        mealExtractions.any((m) => m.containsAlcohol == true);
    final hasSugarHeavy =
        mealExtractions.any((m) => m.containsSugar == true);
    final hasLateMeal =
        mealExtractions.any((m) => m.isLateNightMeal == true);
    final hasHeavyEvening =
        mealExtractions.any((m) => m.isHeavyMeal == true && m.isLateNightMeal == true);

    // Parse diary stressors/gratitude counts
    int? stressorCount;
    int? gratitudeCount;
    int? unresolvedWorryCount;
    if (diaryEntry != null) {
      try {
        if (diaryEntry.stressors != null) {
          final list = jsonDecode(diaryEntry.stressors!) as List;
          stressorCount = list.length;
        }
        if (diaryEntry.gratitude != null) {
          final list = jsonDecode(diaryEntry.gratitude!) as List;
          gratitudeCount = list.length;
        }
      } catch (_) {}
    }

    // Day of week
    final dayOfWeek = date.weekday; // 1=Mon, 7=Sun
    final isWeekend = dayOfWeek >= 6;

    // Compute sleep duration
    double? sleepDuration;
    if (sleepEntry?.bedTime != null && sleepEntry?.wakeTime != null) {
      sleepDuration = sleepEntry!.wakeTime!
              .difference(sleepEntry.bedTime!)
              .inMinutes /
          60.0;
    } else if (sleepExtraction?.estimatedSleepHours != null) {
      sleepDuration = sleepExtraction!.estimatedSleepHours!.toDouble();
    }

    // Compute composite score (weighted average of available metrics)
    double? compositeScore;
    final scores = <double>[];
    if (sleepExtraction?.sleepQuality != null) scores.add(sleepExtraction!.sleepQuality! / 5.0);
    if (sleepExtraction?.moodRating != null) scores.add(sleepExtraction!.moodRating! / 5.0);
    if (sleepExtraction?.energyLevel != null) scores.add(sleepExtraction!.energyLevel! / 5.0);
    if (scores.isNotEmpty) {
      compositeScore = scores.reduce((a, b) => a + b) / scores.length;
    }

    // Upsert the nightly features row
    await _db.into(_db.nightlyFeatures).insertOnConflictUpdate(
      NightlyFeaturesCompanion(
        date: Value(startOfDay),
        sleepQuality: Value(sleepExtraction?.sleepQuality ?? sleepEntry?.qualityRating),
        moodMorning: Value(sleepExtraction?.moodRating ?? sleepEntry?.moodRating),
        energyLevel: Value(sleepExtraction?.energyLevel),
        sleepDurationHours: Value(sleepDuration),
        wakeUpCount: Value(sleepExtraction?.wakeUpCount),
        dreamRecalled: Value(sleepExtraction?.dreamRecalled),
        dreamValence: Value(sleepExtraction?.dreamValence),
        physicalSymptoms: Value(
          sleepExtraction?.physicalSymptoms.isNotEmpty == true
              ? jsonEncode(sleepExtraction!.physicalSymptoms)
              : null,
        ),
        dayRating: Value(diaryEntry?.overallDayRating),
        stressLevel: Value(null), // from diary extraction if stored
        moodEvening: Value(diaryEntry?.mood),
        stressorCount: Value(stressorCount),
        gratitudeCount: Value(gratitudeCount),
        diaryCompleted: Value(diaryEntry != null),
        unresolvedWorryCount: Value(unresolvedWorryCount),
        exercisedToday: Value(null), // from diary extraction
        hadAlcohol: Value(hasAlcoholInMeals),
        caffeineAfter2pm: Value(sleepExtraction?.hadCaffeineYesterday ?? hasCaffeineInMeals),
        screenBeforeBed: Value(sleepExtraction?.screenBeforeBed),
        lateMeal: Value(hasLateMeal),
        heavyMealEvening: Value(hasHeavyEvening),
        socialInteraction: Value(null),
        workedLate: Value(null),
        mealCount: Value(meals.length),
        caffeineInMeals: Value(hasCaffeineInMeals),
        alcoholInMeals: Value(hasAlcoholInMeals),
        sugarHeavyMeal: Value(hasSugarHeavy),
        dayOfWeek: Value(dayOfWeek),
        isWeekend: Value(isWeekend),
        compositeScore: Value(compositeScore),
        overallSentiment: Value(sleepExtraction?.overallSentiment),
      ),
    );
  }

  /// Recompute features for a date range (backfill)
  Future<void> backfillFeatures({
    required DateTime from,
    required DateTime to,
  }) async {
    var current = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);

    while (!current.isAfter(end)) {
      await computeFeaturesForDate(current);
      current = current.add(const Duration(days: 1));
    }
  }

  /// Get all nightly features for a date range
  Future<List<NightlyFeature>> getFeaturesInRange(
      DateTime start, DateTime end) async {
    return (await (_db.select(_db.nightlyFeatures)
              ..where((f) => f.date.isBetweenValues(start, end))
              ..orderBy([(f) => OrderingTerm.asc(f.date)]))
            .get());
  }

  /// Get the most recent N nights of features
  Future<List<NightlyFeature>> getRecentFeatures({int count = 30}) async {
    return (await (_db.select(_db.nightlyFeatures)
              ..orderBy([(f) => OrderingTerm.desc(f.date)])
              ..limit(count))
            .get());
  }

  /// Compute correlation between a boolean feature and sleep quality
  /// Returns Pearson correlation coefficient (-1 to 1)
  double? computeBoolCorrelation(
    List<NightlyFeature> features,
    bool? Function(NightlyFeature) featureExtractor,
  ) {
    final pairs = <(double, double)>[];

    for (final f in features) {
      final quality = f.sleepQuality;
      final featureVal = featureExtractor(f);
      if (quality != null && featureVal != null) {
        pairs.add((featureVal ? 1.0 : 0.0, quality.toDouble()));
      }
    }

    if (pairs.length < 5) return null; // Not enough data

    return _pearsonCorrelation(pairs);
  }

  /// Compute correlation between a numeric feature and sleep quality
  double? computeNumericCorrelation(
    List<NightlyFeature> features,
    double? Function(NightlyFeature) featureExtractor,
  ) {
    final pairs = <(double, double)>[];

    for (final f in features) {
      final quality = f.sleepQuality;
      final featureVal = featureExtractor(f);
      if (quality != null && featureVal != null) {
        pairs.add((featureVal, quality.toDouble()));
      }
    }

    if (pairs.length < 5) return null;

    return _pearsonCorrelation(pairs);
  }

  /// Pearson correlation coefficient
  double _pearsonCorrelation(List<(double, double)> pairs) {
    final n = pairs.length;
    if (n == 0) return 0;

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0, sumY2 = 0;

    for (final (x, y) in pairs) {
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
      sumY2 += y * y;
    }

    final numerator = (n * sumXY) - (sumX * sumY);
    final denominator =
        _sqrt(((n * sumX2) - (sumX * sumX)) * ((n * sumY2) - (sumY * sumY)));

    if (denominator == 0) return 0;
    return numerator / denominator;
  }

  double _sqrt(double value) {
    if (value <= 0) return 0;
    // Newton's method for sqrt
    double guess = value / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + value / guess) / 2;
    }
    return guess;
  }

  /// Get top correlations with sleep quality from recent data
  Future<List<FeatureCorrelation>> getTopCorrelations({int days = 30}) async {
    final features = await getRecentFeatures(count: days);
    if (features.length < 7) return []; // Need at least a week of data

    final correlations = <FeatureCorrelation>[];

    // Boolean features
    final boolFeatures = <String, bool? Function(NightlyFeature)>{
      'Diary completed': (f) => f.diaryCompleted,
      'Late meal': (f) => f.lateMeal,
      'Caffeine after 2 PM': (f) => f.caffeineAfter2pm,
      'Alcohol': (f) => f.hadAlcohol,
      'Screen before bed': (f) => f.screenBeforeBed,
      'Dream recalled': (f) => f.dreamRecalled,
      'Heavy evening meal': (f) => f.heavyMealEvening,
      'Weekend': (f) => f.isWeekend,
      'Exercised': (f) => f.exercisedToday,
    };

    for (final entry in boolFeatures.entries) {
      final corr = computeBoolCorrelation(features, entry.value);
      if (corr != null && corr.abs() > 0.15) {
        correlations.add(FeatureCorrelation(
          featureName: entry.key,
          correlation: corr,
          sampleSize: features.length,
        ));
      }
    }

    // Numeric features
    final numFeatures = <String, double? Function(NightlyFeature)>{
      'Stress level': (f) => f.stressLevel?.toDouble(),
      'Day rating': (f) => f.dayRating?.toDouble(),
      'Gratitude count': (f) => f.gratitudeCount?.toDouble(),
      'Stressor count': (f) => f.stressorCount?.toDouble(),
      'Sleep duration': (f) => f.sleepDurationHours,
      'Meals logged': (f) => f.mealCount?.toDouble(),
    };

    for (final entry in numFeatures.entries) {
      final corr = computeNumericCorrelation(features, entry.value);
      if (corr != null && corr.abs() > 0.15) {
        correlations.add(FeatureCorrelation(
          featureName: entry.key,
          correlation: corr,
          sampleSize: features.length,
        ));
      }
    }

    // Sort by absolute correlation strength
    correlations.sort((a, b) => b.correlation.abs().compareTo(a.correlation.abs()));
    return correlations.take(10).toList();
  }
}

/// Represents a correlation between a feature and sleep quality
class FeatureCorrelation {
  final String featureName;
  final double correlation; // -1 to 1
  final int sampleSize;

  FeatureCorrelation({
    required this.featureName,
    required this.correlation,
    required this.sampleSize,
  });

  /// Human-readable interpretation
  String get interpretation {
    final direction = correlation > 0 ? 'improves' : 'worsens';
    final strength = correlation.abs() > 0.5
        ? 'strongly'
        : correlation.abs() > 0.3
            ? 'moderately'
            : 'slightly';
    return '$featureName $strength $direction your sleep quality';
  }

  Map<String, dynamic> toJson() => {
        'feature': featureName,
        'correlation': correlation,
        'sample_size': sampleSize,
        'interpretation': interpretation,
      };
}

final featureEngineeringProvider = Provider<FeatureEngineeringService>((ref) {
  return FeatureEngineeringService(DatabaseService.instance.database);
});
