import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/core/database/app_database.dart';
import 'package:sleepy_habbit/core/models/user_profile.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';
import 'package:sleepy_habbit/core/services/feature_engineering_service.dart';
import 'package:sleepy_habbit/core/services/llm_service.dart';

/// Full monthly analysis report model
class MonthlyAnalysis {
  final DateTime monthStart;
  final DateTime monthEnd;
  final int totalNights;
  final MonthlyStats stats;
  final List<WeekSummary> weeklyBreakdown;
  final List<FeatureCorrelation> topCorrelations;
  final List<PatternInsight> patterns;
  final String narrative; // LLM-generated comprehensive narrative
  final List<String> recommendations;
  final TrendAnalysis trends;

  MonthlyAnalysis({
    required this.monthStart,
    required this.monthEnd,
    required this.totalNights,
    required this.stats,
    required this.weeklyBreakdown,
    required this.topCorrelations,
    required this.patterns,
    required this.narrative,
    required this.recommendations,
    required this.trends,
  });

  Map<String, dynamic> toJson() => {
        'month_start': monthStart.toIso8601String(),
        'month_end': monthEnd.toIso8601String(),
        'total_nights': totalNights,
        'stats': stats.toJson(),
        'weekly_breakdown': weeklyBreakdown.map((w) => w.toJson()).toList(),
        'top_correlations': topCorrelations.map((c) => c.toJson()).toList(),
        'patterns': patterns.map((p) => p.toJson()).toList(),
        'narrative': narrative,
        'recommendations': recommendations,
        'trends': trends.toJson(),
      };
}

class MonthlyStats {
  final double? avgQuality;
  final double? avgMood;
  final double? avgDuration;
  final double? avgStress;
  final int daysWithDiary;
  final int totalMeals;
  final double? diaryCompletionRate;
  final int dreamsRecalled;
  final int goodNights; // quality >= 4
  final int badNights; // quality <= 2

  MonthlyStats({
    this.avgQuality,
    this.avgMood,
    this.avgDuration,
    this.avgStress,
    this.daysWithDiary = 0,
    this.totalMeals = 0,
    this.diaryCompletionRate,
    this.dreamsRecalled = 0,
    this.goodNights = 0,
    this.badNights = 0,
  });

  Map<String, dynamic> toJson() => {
        'avg_quality': avgQuality?.toStringAsFixed(2),
        'avg_mood': avgMood?.toStringAsFixed(2),
        'avg_duration': avgDuration?.toStringAsFixed(1),
        'avg_stress': avgStress?.toStringAsFixed(2),
        'days_with_diary': daysWithDiary,
        'total_meals': totalMeals,
        'diary_completion_rate':
            diaryCompletionRate?.toStringAsFixed(0),
        'dreams_recalled': dreamsRecalled,
        'good_nights': goodNights,
        'bad_nights': badNights,
      };
}

class WeekSummary {
  final int weekNumber;
  final double? avgQuality;
  final double? avgMood;
  final int nights;
  final String? dominantMood;
  final List<String> notableEvents;

  WeekSummary({
    required this.weekNumber,
    this.avgQuality,
    this.avgMood,
    this.nights = 0,
    this.dominantMood,
    this.notableEvents = const [],
  });

  Map<String, dynamic> toJson() => {
        'week': weekNumber,
        'avg_quality': avgQuality?.toStringAsFixed(1),
        'avg_mood': avgMood?.toStringAsFixed(1),
        'nights': nights,
        'dominant_mood': dominantMood,
        'notable_events': notableEvents,
      };
}

class PatternInsight {
  final String category; // 'temporal', 'behavioral', 'emotional', 'nutritional'
  final String description;
  final double confidence; // 0-1
  final String evidence;

  PatternInsight({
    required this.category,
    required this.description,
    required this.confidence,
    required this.evidence,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'description': description,
        'confidence': confidence,
        'evidence': evidence,
      };
}

class TrendAnalysis {
  final String qualityTrend; // 'improving', 'declining', 'stable'
  final String moodTrend;
  final String durationTrend;
  final double? qualityChange; // week 4 avg - week 1 avg
  final String bestDayOfWeek;
  final String worstDayOfWeek;

  TrendAnalysis({
    this.qualityTrend = 'stable',
    this.moodTrend = 'stable',
    this.durationTrend = 'stable',
    this.qualityChange,
    this.bestDayOfWeek = 'Unknown',
    this.worstDayOfWeek = 'Unknown',
  });

  Map<String, dynamic> toJson() => {
        'quality_trend': qualityTrend,
        'mood_trend': moodTrend,
        'duration_trend': durationTrend,
        'quality_change': qualityChange?.toStringAsFixed(2),
        'best_day_of_week': bestDayOfWeek,
        'worst_day_of_week': worstDayOfWeek,
      };
}

/// Service that performs comprehensive monthly analysis
class MonthlyAnalysisService {
  final AppDatabase _db;
  final FeatureEngineeringService _features;
  final LlmService _llm;

  MonthlyAnalysisService(this._db, this._features, this._llm);

  /// Generate full monthly analysis report
  Future<MonthlyAnalysis?> generateMonthlyAnalysis({
    DateTime? monthStart,
  }) async {
    final start = monthStart ??
        DateTime.now().subtract(const Duration(days: 30));
    final end = DateTime.now();

    // Get all nightly features for the month
    final allFeatures = await _features.getFeaturesInRange(start, end);
    if (allFeatures.length < 7) return null; // Need at least a week

    // Compute stats
    final stats = _computeStats(allFeatures);

    // Weekly breakdown
    final weeks = _computeWeeklyBreakdown(allFeatures);

    // Correlations
    final correlations = await _features.getTopCorrelations(days: 30);

    // Pattern discovery
    final patterns = _discoverPatterns(allFeatures);

    // Trend analysis
    final trends = _analyzeTrends(allFeatures, weeks);

    // Load user profile for personalization
    final profile = await UserProfile.load();

    // Generate LLM narrative
    final narrative = await _generateFullNarrative(
      stats: stats,
      weeks: weeks,
      correlations: correlations,
      patterns: patterns,
      trends: trends,
      profile: profile,
    );

    // Generate recommendations
    final recommendations = await _generateDetailedRecommendations(
      stats: stats,
      correlations: correlations,
      patterns: patterns,
      trends: trends,
      profile: profile,
    );

    return MonthlyAnalysis(
      monthStart: start,
      monthEnd: end,
      totalNights: allFeatures.length,
      stats: stats,
      weeklyBreakdown: weeks,
      topCorrelations: correlations,
      patterns: patterns,
      narrative: narrative,
      recommendations: recommendations,
      trends: trends,
    );
  }

  MonthlyStats _computeStats(List<NightlyFeature> features) {
    final qualities = features
        .map((f) => f.sleepQuality)
        .whereType<int>()
        .toList();
    final moods = features
        .map((f) => f.moodMorning)
        .whereType<int>()
        .toList();
    final durations = features
        .map((f) => f.sleepDurationHours)
        .whereType<double>()
        .toList();
    final stresses = features
        .map((f) => f.stressLevel)
        .whereType<int>()
        .toList();

    return MonthlyStats(
      avgQuality: qualities.isEmpty
          ? null
          : qualities.reduce((a, b) => a + b) / qualities.length,
      avgMood: moods.isEmpty
          ? null
          : moods.reduce((a, b) => a + b) / moods.length,
      avgDuration: durations.isEmpty
          ? null
          : durations.reduce((a, b) => a + b) / durations.length,
      avgStress: stresses.isEmpty
          ? null
          : stresses.reduce((a, b) => a + b) / stresses.length,
      daysWithDiary: features.where((f) => f.diaryCompleted).length,
      diaryCompletionRate: features.isEmpty
          ? null
          : features.where((f) => f.diaryCompleted).length / features.length * 100,
      dreamsRecalled: features.where((f) => f.dreamRecalled == true).length,
      goodNights: qualities.where((q) => q >= 4).length,
      badNights: qualities.where((q) => q <= 2).length,
    );
  }

  List<WeekSummary> _computeWeeklyBreakdown(List<NightlyFeature> features) {
    final weeks = <WeekSummary>[];
    const chunkSize = 7;

    for (int i = 0; i < features.length; i += chunkSize) {
      final end = (i + chunkSize).clamp(0, features.length);
      final weekFeatures = features.sublist(i, end);
      final weekNum = (i ~/ chunkSize) + 1;

      final qualities = weekFeatures
          .map((f) => f.sleepQuality)
          .whereType<int>()
          .toList();
      final moods = weekFeatures
          .map((f) => f.moodMorning)
          .whereType<int>()
          .toList();

      // Find dominant evening mood
      final eveningMoods = weekFeatures
          .map((f) => f.moodEvening)
          .whereType<String>()
          .toList();
      final dominantMood = eveningMoods.isEmpty
          ? null
          : _mostCommon(eveningMoods);

      // Notable events (bad nights, good streaks, etc.)
      final notable = <String>[];
      final badNights = weekFeatures.where((f) =>
          f.sleepQuality != null && f.sleepQuality! <= 2);
      if (badNights.length >= 2) notable.add('${badNights.length} rough nights');
      final goodNights = weekFeatures.where((f) =>
          f.sleepQuality != null && f.sleepQuality! >= 4);
      if (goodNights.length >= 4) notable.add('${goodNights.length} great nights!');

      weeks.add(WeekSummary(
        weekNumber: weekNum,
        avgQuality: qualities.isEmpty
            ? null
            : qualities.reduce((a, b) => a + b) / qualities.length,
        avgMood: moods.isEmpty
            ? null
            : moods.reduce((a, b) => a + b) / moods.length,
        nights: weekFeatures.length,
        dominantMood: dominantMood,
        notableEvents: notable,
      ));
    }

    return weeks;
  }

  List<PatternInsight> _discoverPatterns(List<NightlyFeature> features) {
    final patterns = <PatternInsight>[];

    // Day-of-week patterns
    final byDow = <int, List<int>>{};
    for (final f in features) {
      if (f.dayOfWeek != null && f.sleepQuality != null) {
        byDow.putIfAbsent(f.dayOfWeek!, () => []).add(f.sleepQuality!);
      }
    }
    final dowAvgs = byDow.map(
      (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
    );
    if (dowAvgs.isNotEmpty) {
      final best = dowAvgs.entries.reduce((a, b) => a.value > b.value ? a : b);
      final worst = dowAvgs.entries.reduce((a, b) => a.value < b.value ? a : b);
      if (best.value - worst.value > 0.5) {
        patterns.add(PatternInsight(
          category: 'temporal',
          description:
              '${_dayName(best.key)} nights are your best (avg ${best.value.toStringAsFixed(1)}/5), '
              'while ${_dayName(worst.key)} nights are your worst (avg ${worst.value.toStringAsFixed(1)}/5)',
          confidence: 0.7,
          evidence: '${features.length} nights analyzed',
        ));
      }
    }

    // Diary impact pattern
    final withDiary = features.where((f) => f.diaryCompleted).toList();
    final withoutDiary = features.where((f) => !f.diaryCompleted).toList();
    if (withDiary.length >= 3 && withoutDiary.length >= 3) {
      final avgWith = _avgQuality(withDiary);
      final avgWithout = _avgQuality(withoutDiary);
      if (avgWith != null && avgWithout != null && (avgWith - avgWithout).abs() > 0.3) {
        patterns.add(PatternInsight(
          category: 'behavioral',
          description: avgWith > avgWithout
              ? 'Evening diary is strongly linked to better sleep (+${(avgWith - avgWithout).toStringAsFixed(1)} quality)'
              : 'Evening diary doesn\'t seem to be helping your sleep currently',
          confidence: 0.8,
          evidence: '${withDiary.length} diary nights vs ${withoutDiary.length} non-diary nights',
        ));
      }
    }

    // Stress → sleep pattern
    final highStress = features.where((f) =>
        f.stressorCount != null && f.stressorCount! >= 2).toList();
    final lowStress = features.where((f) =>
        f.stressorCount != null && f.stressorCount! == 0).toList();
    if (highStress.length >= 3 && lowStress.length >= 3) {
      final avgHigh = _avgQuality(highStress);
      final avgLow = _avgQuality(lowStress);
      if (avgHigh != null && avgLow != null && avgLow - avgHigh > 0.5) {
        patterns.add(PatternInsight(
          category: 'emotional',
          description:
              'Multiple stressors in the evening drop your sleep quality by '
              '${(avgLow - avgHigh).toStringAsFixed(1)} points on average',
          confidence: 0.75,
          evidence: '${highStress.length} stressed nights vs ${lowStress.length} calm nights',
        ));
      }
    }

    // Caffeine pattern
    final withCaffeine = features.where((f) => f.caffeineAfter2pm == true).toList();
    final noCaffeine = features.where((f) => f.caffeineAfter2pm == false).toList();
    if (withCaffeine.length >= 3 && noCaffeine.length >= 3) {
      final avgCaff = _avgQuality(withCaffeine);
      final avgNoCaff = _avgQuality(noCaffeine);
      if (avgCaff != null && avgNoCaff != null && avgNoCaff - avgCaff > 0.3) {
        patterns.add(PatternInsight(
          category: 'nutritional',
          description:
              'Afternoon caffeine costs you about '
              '${(avgNoCaff - avgCaff).toStringAsFixed(1)} points of sleep quality',
          confidence: 0.7,
          evidence: '${withCaffeine.length} caffeine days vs ${noCaffeine.length} caffeine-free days',
        ));
      }
    }

    return patterns;
  }

  TrendAnalysis _analyzeTrends(
    List<NightlyFeature> features,
    List<WeekSummary> weeks,
  ) {
    // Overall trend direction
    String qualityTrend = 'stable';
    String moodTrend = 'stable';
    String durationTrend = 'stable';
    double? qualityChange;

    if (weeks.length >= 2) {
      final first = weeks.first;
      final last = weeks.last;
      if (first.avgQuality != null && last.avgQuality != null) {
        qualityChange = last.avgQuality! - first.avgQuality!;
        if (qualityChange > 0.3) qualityTrend = 'improving';
        if (qualityChange < -0.3) qualityTrend = 'declining';
      }
      if (first.avgMood != null && last.avgMood != null) {
        final moodChange = last.avgMood! - first.avgMood!;
        if (moodChange > 0.3) moodTrend = 'improving';
        if (moodChange < -0.3) moodTrend = 'declining';
      }
    }

    // Best/worst day of week
    final byDow = <int, List<int>>{};
    for (final f in features) {
      if (f.dayOfWeek != null && f.sleepQuality != null) {
        byDow.putIfAbsent(f.dayOfWeek!, () => []).add(f.sleepQuality!);
      }
    }
    String bestDay = 'Unknown';
    String worstDay = 'Unknown';
    if (byDow.isNotEmpty) {
      final dowAvgs = byDow.map(
        (k, v) => MapEntry(k, v.reduce((a, b) => a + b) / v.length),
      );
      final best = dowAvgs.entries.reduce((a, b) => a.value > b.value ? a : b);
      final worst = dowAvgs.entries.reduce((a, b) => a.value < b.value ? a : b);
      bestDay = _dayName(best.key);
      worstDay = _dayName(worst.key);
    }

    return TrendAnalysis(
      qualityTrend: qualityTrend,
      moodTrend: moodTrend,
      durationTrend: durationTrend,
      qualityChange: qualityChange,
      bestDayOfWeek: bestDay,
      worstDayOfWeek: worstDay,
    );
  }

  Future<String> _generateFullNarrative({
    required MonthlyStats stats,
    required List<WeekSummary> weeks,
    required List<FeatureCorrelation> correlations,
    required List<PatternInsight> patterns,
    required TrendAnalysis trends,
    required UserProfile profile,
  }) async {
    final prompt = StringBuffer();
    prompt.writeln('MONTHLY SLEEP ANALYSIS DATA:');
    prompt.writeln('');
    prompt.writeln('USER CONTEXT:');
    prompt.writeln('- Name: ${profile.name ?? "User"}');
    prompt.writeln('- Sleep goal: ${profile.sleepGoal ?? "General improvement"}');
    prompt.writeln('- Known issues: ${profile.sleepIssues.join(", ")}');
    prompt.writeln('- Known factors: ${profile.knownFactors.join(", ")}');
    prompt.writeln('');
    prompt.writeln('OVERALL STATS:');
    prompt.writeln('- Avg quality: ${stats.avgQuality?.toStringAsFixed(1) ?? "N/A"}/5');
    prompt.writeln('- Avg mood: ${stats.avgMood?.toStringAsFixed(1) ?? "N/A"}/5');
    prompt.writeln('- Avg duration: ${stats.avgDuration?.toStringAsFixed(1) ?? "N/A"} hours');
    prompt.writeln('- Good nights (4+): ${stats.goodNights}');
    prompt.writeln('- Bad nights (2-): ${stats.badNights}');
    prompt.writeln('- Diary completion: ${stats.diaryCompletionRate?.toStringAsFixed(0) ?? "?"}%');
    prompt.writeln('- Dreams recalled: ${stats.dreamsRecalled}');
    prompt.writeln('');
    prompt.writeln('TREND: Sleep quality is ${trends.qualityTrend}');
    prompt.writeln('Best day: ${trends.bestDayOfWeek}, Worst: ${trends.worstDayOfWeek}');
    prompt.writeln('');
    prompt.writeln('WEEK-BY-WEEK:');
    for (final w in weeks) {
      prompt.writeln('Week ${w.weekNumber}: quality=${w.avgQuality?.toStringAsFixed(1) ?? "?"}, '
          'mood=${w.avgMood?.toStringAsFixed(1) ?? "?"}, ${w.nights} nights'
          '${w.notableEvents.isNotEmpty ? " - ${w.notableEvents.join(", ")}" : ""}');
    }
    prompt.writeln('');
    prompt.writeln('KEY PATTERNS DISCOVERED:');
    for (final p in patterns) {
      prompt.writeln('- [${p.category}] ${p.description} (confidence: ${(p.confidence * 100).round()}%)');
    }
    prompt.writeln('');
    prompt.writeln('TOP CORRELATIONS:');
    for (final c in correlations.take(5)) {
      prompt.writeln('- ${c.interpretation} (r=${c.correlation.toStringAsFixed(2)})');
    }

    return _llm.chat(
      messages: [
        {
          'role': 'system',
          'content': '''You are a sleep specialist writing a comprehensive monthly analysis for a patient.
Write a detailed, empathetic narrative report (5-6 paragraphs) covering:
1. Opening: Overall month summary — acknowledge their effort in tracking
2. The story of the month: How did things evolve week to week? What changed?
3. Key discoveries: The most important patterns found in their specific data
4. The science: Briefly explain WHY certain correlations exist (backed by research)
5. Progress toward their goal: Are they getting closer? What's working?
6. Looking ahead: 2-3 specific, personalized actions for next month

Tone: warm, knowledgeable, encouraging. Like a caring sleep doctor who knows them well.
Use their name if provided. Reference specific data points.
Don't be generic — every sentence should be grounded in THEIR data.'''
        },
        {'role': 'user', 'content': prompt.toString()},
      ],
      maxTokens: 1200,
      temperature: 0.7,
    );
  }

  Future<List<String>> _generateDetailedRecommendations({
    required MonthlyStats stats,
    required List<FeatureCorrelation> correlations,
    required List<PatternInsight> patterns,
    required TrendAnalysis trends,
    required UserProfile profile,
  }) async {
    final recommendations = <String>[];

    // Data-driven recommendations
    if (stats.diaryCompletionRate != null && stats.diaryCompletionRate! < 50) {
      recommendations.add(
          'Increase evening diary usage — your data shows it correlates with better sleep.');
    }

    for (final pattern in patterns) {
      if (pattern.confidence > 0.6) {
        if (pattern.category == 'nutritional') {
          recommendations.add(
              'Nutrition adjustment: ${pattern.description}');
        } else if (pattern.category == 'behavioral') {
          recommendations.add(
              'Habit insight: ${pattern.description}');
        }
      }
    }

    // Goal-specific
    if (profile.sleepIssues.contains('falling_asleep')) {
      recommendations.add(
          'For falling asleep faster: maintain the diary habit and avoid screens 30min before bed.');
    }
    if (profile.sleepIssues.contains('racing_thoughts')) {
      recommendations.add(
          'For racing thoughts: the evening diary is your best tool. Try to include a "worry dump" section.');
    }

    // Trend-based
    if (trends.qualityTrend == 'declining') {
      recommendations.add(
          'Your sleep quality has been declining — review what changed in recent weeks and consider adjusting.');
    } else if (trends.qualityTrend == 'improving') {
      recommendations.add(
          'Great trajectory! Whatever you changed recently is working — keep it up.');
    }

    // Always add a consistency recommendation
    recommendations.add(
        'Keep logging consistently — the more data, the more accurate the insights become.');

    return recommendations.take(5).toList();
  }

  // --- Helpers ---

  double? _avgQuality(List<NightlyFeature> features) {
    final values = features
        .map((f) => f.sleepQuality)
        .whereType<int>()
        .toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _dayName(int dow) {
    const names = ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    if (dow >= 1 && dow <= 7) return names[dow];
    return 'Unknown';
  }

  String? _mostCommon(List<String> items) {
    if (items.isEmpty) return null;
    final counts = <String, int>{};
    for (final item in items) {
      counts[item] = (counts[item] ?? 0) + 1;
    }
    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

final monthlyAnalysisServiceProvider = Provider<MonthlyAnalysisService>((ref) {
  final db = DatabaseService.instance.database;
  final features = ref.read(featureEngineeringProvider);
  final llm = ref.read(llmServiceProvider);
  return MonthlyAnalysisService(db, features, llm);
});
