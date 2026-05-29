import 'dart:convert';

/// Structured data extracted from morning interview conversations
class SleepExtractionData {
  final int? sleepQuality; // 1-5
  final int? moodRating; // 1-5
  final int? energyLevel; // 1-5
  final bool? dreamRecalled;
  final String? dreamValence; // positive, negative, neutral, mixed
  final List<String> dreamThemes;
  final List<String> physicalSymptoms; // headache, stiffness, refreshed, etc.
  final int? estimatedSleepHours;
  final int? wakeUpCount; // number of times woke up during night
  final String? bedTimeEstimate; // e.g. "11:30 PM"
  final bool? hadCaffeineYesterday;
  final bool? screenBeforeBed;
  final String? overallSentiment; // positive, negative, neutral

  SleepExtractionData({
    this.sleepQuality,
    this.moodRating,
    this.energyLevel,
    this.dreamRecalled,
    this.dreamValence,
    this.dreamThemes = const [],
    this.physicalSymptoms = const [],
    this.estimatedSleepHours,
    this.wakeUpCount,
    this.bedTimeEstimate,
    this.hadCaffeineYesterday,
    this.screenBeforeBed,
    this.overallSentiment,
  });

  factory SleepExtractionData.fromJson(Map<String, dynamic> json) {
    return SleepExtractionData(
      sleepQuality: json['sleep_quality'] as int?,
      moodRating: json['mood_rating'] as int?,
      energyLevel: json['energy_level'] as int?,
      dreamRecalled: json['dream_recalled'] as bool?,
      dreamValence: json['dream_valence'] as String?,
      dreamThemes: (json['dream_themes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      physicalSymptoms: (json['physical_symptoms'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      estimatedSleepHours: json['estimated_sleep_hours'] as int?,
      wakeUpCount: json['wake_up_count'] as int?,
      bedTimeEstimate: json['bed_time_estimate'] as String?,
      hadCaffeineYesterday: json['had_caffeine_yesterday'] as bool?,
      screenBeforeBed: json['screen_before_bed'] as bool?,
      overallSentiment: json['overall_sentiment'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'sleep_quality': sleepQuality,
        'mood_rating': moodRating,
        'energy_level': energyLevel,
        'dream_recalled': dreamRecalled,
        'dream_valence': dreamValence,
        'dream_themes': dreamThemes,
        'physical_symptoms': physicalSymptoms,
        'estimated_sleep_hours': estimatedSleepHours,
        'wake_up_count': wakeUpCount,
        'bed_time_estimate': bedTimeEstimate,
        'had_caffeine_yesterday': hadCaffeineYesterday,
        'screen_before_bed': screenBeforeBed,
        'overall_sentiment': overallSentiment,
      };

  String toJsonString() => jsonEncode(toJson());
}

/// Structured data extracted from evening diary conversations
class DiaryExtractionData {
  final int? overallDayRating; // 1-5
  final String? mood; // anxious, calm, happy, sad, stressed, neutral, etc.
  final int? stressLevel; // 1-5
  final List<String> stressors;
  final List<String> gratitudeItems;
  final List<String> highlights;
  final List<String> lowlights;
  final String? tomorrowIntentions;
  final bool? exercisedToday;
  final bool? socialInteraction;
  final bool? workedLate;
  final bool? hadAlcohol;
  final bool? caffeineAfter2pm;
  final String? lastMealApproxTime; // e.g. "9 PM"
  final String? overallSentiment; // positive, negative, neutral, mixed
  final List<String> unresolvedWorries;

  DiaryExtractionData({
    this.overallDayRating,
    this.mood,
    this.stressLevel,
    this.stressors = const [],
    this.gratitudeItems = const [],
    this.highlights = const [],
    this.lowlights = const [],
    this.tomorrowIntentions,
    this.exercisedToday,
    this.socialInteraction,
    this.workedLate,
    this.hadAlcohol,
    this.caffeineAfter2pm,
    this.lastMealApproxTime,
    this.overallSentiment,
    this.unresolvedWorries = const [],
  });

  factory DiaryExtractionData.fromJson(Map<String, dynamic> json) {
    return DiaryExtractionData(
      overallDayRating: json['overall_day_rating'] as int?,
      mood: json['mood'] as String?,
      stressLevel: json['stress_level'] as int?,
      stressors: (json['stressors'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      gratitudeItems: (json['gratitude_items'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      lowlights: (json['lowlights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tomorrowIntentions: json['tomorrow_intentions'] as String?,
      exercisedToday: json['exercised_today'] as bool?,
      socialInteraction: json['social_interaction'] as bool?,
      workedLate: json['worked_late'] as bool?,
      hadAlcohol: json['had_alcohol'] as bool?,
      caffeineAfter2pm: json['caffeine_after_2pm'] as bool?,
      lastMealApproxTime: json['last_meal_approx_time'] as String?,
      overallSentiment: json['overall_sentiment'] as String?,
      unresolvedWorries: (json['unresolved_worries'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'overall_day_rating': overallDayRating,
        'mood': mood,
        'stress_level': stressLevel,
        'stressors': stressors,
        'gratitude_items': gratitudeItems,
        'highlights': highlights,
        'lowlights': lowlights,
        'tomorrow_intentions': tomorrowIntentions,
        'exercised_today': exercisedToday,
        'social_interaction': socialInteraction,
        'worked_late': workedLate,
        'had_alcohol': hadAlcohol,
        'caffeine_after_2pm': caffeineAfter2pm,
        'last_meal_approx_time': lastMealApproxTime,
        'overall_sentiment': overallSentiment,
        'unresolved_worries': unresolvedWorries,
      };

  String toJsonString() => jsonEncode(toJson());
}

/// Structured data extracted from meal entries
class MealExtractionData {
  final bool? isHeavyMeal;
  final bool? containsCaffeine;
  final bool? containsAlcohol;
  final bool? containsSugar;
  final bool? isLateNightMeal; // within 2 hours of typical bedtime
  final List<String> foodCategories; // protein, carbs, vegetables, junk, etc.
  final String? sleepImpactRating; // positive, negative, neutral

  MealExtractionData({
    this.isHeavyMeal,
    this.containsCaffeine,
    this.containsAlcohol,
    this.containsSugar,
    this.isLateNightMeal,
    this.foodCategories = const [],
    this.sleepImpactRating,
  });

  factory MealExtractionData.fromJson(Map<String, dynamic> json) {
    return MealExtractionData(
      isHeavyMeal: json['is_heavy_meal'] as bool?,
      containsCaffeine: json['contains_caffeine'] as bool?,
      containsAlcohol: json['contains_alcohol'] as bool?,
      containsSugar: json['contains_sugar'] as bool?,
      isLateNightMeal: json['is_late_night_meal'] as bool?,
      foodCategories: (json['food_categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      sleepImpactRating: json['sleep_impact_rating'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'is_heavy_meal': isHeavyMeal,
        'contains_caffeine': containsCaffeine,
        'contains_alcohol': containsAlcohol,
        'contains_sugar': containsSugar,
        'is_late_night_meal': isLateNightMeal,
        'food_categories': foodCategories,
        'sleep_impact_rating': sleepImpactRating,
      };

  String toJsonString() => jsonEncode(toJson());
}
