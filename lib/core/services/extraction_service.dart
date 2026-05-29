import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sleepy_habbit/core/models/extracted_data.dart';
import 'package:sleepy_habbit/core/services/llm_service.dart';

/// Service responsible for extracting structured data from conversations
/// using the LLM. This runs after each session completes to create
/// clean, analyzable features from unstructured voice transcriptions.
class ExtractionService {
  final LlmService _llm;

  ExtractionService(this._llm);

  /// Extract structured sleep data from a morning interview transcription
  Future<SleepExtractionData> extractSleepData(String transcription) async {
    final response = await _llm.chat(
      messages: [
        {
          'role': 'system',
          'content': '''You are a data extraction assistant. Given a morning sleep interview transcript, extract structured data into JSON format.
Return ONLY valid JSON with these fields (use null for unknown/not mentioned):
{
  "sleep_quality": <1-5 integer or null>,
  "mood_rating": <1-5 integer or null>,
  "energy_level": <1-5 integer or null>,
  "dream_recalled": <true/false or null>,
  "dream_valence": <"positive"/"negative"/"neutral"/"mixed" or null>,
  "dream_themes": [<list of theme strings>],
  "physical_symptoms": [<list like "headache", "refreshed", "stiffness", "tired eyes">],
  "estimated_sleep_hours": <integer or null>,
  "wake_up_count": <integer or null>,
  "bed_time_estimate": <"HH:MM PM/AM" string or null>,
  "had_caffeine_yesterday": <true/false or null>,
  "screen_before_bed": <true/false or null>,
  "overall_sentiment": <"positive"/"negative"/"neutral" or null>
}

Infer ratings from context if not explicitly stated (e.g., "I slept terribly" = sleep_quality 1-2).
Return ONLY the JSON object, no markdown, no explanation.'''
        },
        {'role': 'user', 'content': transcription},
      ],
      temperature: 0.1, // Low temperature for structured extraction
      maxTokens: 500,
    );

    return _parseSleepExtraction(response);
  }

  /// Extract structured diary data from an evening diary transcription
  Future<DiaryExtractionData> extractDiaryData(String transcription) async {
    final response = await _llm.chat(
      messages: [
        {
          'role': 'system',
          'content': '''You are a data extraction assistant. Given an evening diary transcript, extract structured data into JSON format.
Return ONLY valid JSON with these fields (use null for unknown/not mentioned):
{
  "overall_day_rating": <1-5 integer or null>,
  "mood": <string like "anxious", "calm", "happy", "sad", "stressed", "neutral", "frustrated", "content">,
  "stress_level": <1-5 integer or null>,
  "stressors": [<list of stressor strings>],
  "gratitude_items": [<list of things they're grateful for>],
  "highlights": [<list of positive events>],
  "lowlights": [<list of negative events>],
  "tomorrow_intentions": <string summary or null>,
  "exercised_today": <true/false or null>,
  "social_interaction": <true/false or null>,
  "worked_late": <true/false or null>,
  "had_alcohol": <true/false or null>,
  "caffeine_after_2pm": <true/false or null>,
  "last_meal_approx_time": <"H PM/AM" string or null>,
  "overall_sentiment": <"positive"/"negative"/"neutral"/"mixed">,
  "unresolved_worries": [<list of worries still on their mind>]
}

Infer from context where possible. Return ONLY the JSON object.'''
        },
        {'role': 'user', 'content': transcription},
      ],
      temperature: 0.1,
      maxTokens: 600,
    );

    return _parseDiaryExtraction(response);
  }

  /// Extract structured meal data from meal description and context
  Future<MealExtractionData> extractMealData({
    required String mealDescription,
    required String mealType,
    required int hourOfDay,
    String? llmAnalysis,
  }) async {
    final response = await _llm.chat(
      messages: [
        {
          'role': 'system',
          'content': '''You are a nutrition-sleep analysis assistant. Given a meal description, extract structured data about its potential sleep impact.
Return ONLY valid JSON:
{
  "is_heavy_meal": <true/false>,
  "contains_caffeine": <true/false>,
  "contains_alcohol": <true/false>,
  "contains_sugar": <true/false (high sugar content)>,
  "is_late_night_meal": <true/false (eaten after 8 PM)>,
  "food_categories": [<list like "protein", "carbs", "vegetables", "dairy", "junk_food", "spicy">],
  "sleep_impact_rating": <"positive"/"negative"/"neutral">
}

Consider the time of day when assessing sleep impact. Return ONLY the JSON object.'''
        },
        {
          'role': 'user',
          'content':
              'Meal type: $mealType\nTime: $hourOfDay:00\nDescription: $mealDescription${llmAnalysis != null ? '\nPrior analysis: $llmAnalysis' : ''}'
        },
      ],
      temperature: 0.1,
      maxTokens: 300,
    );

    return _parseMealExtraction(response);
  }

  // --- Parsing helpers with error handling ---

  SleepExtractionData _parseSleepExtraction(String response) {
    try {
      final cleaned = _cleanJsonResponse(response);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return SleepExtractionData.fromJson(json);
    } catch (e) {
      // Return empty extraction on parse failure
      return SleepExtractionData();
    }
  }

  DiaryExtractionData _parseDiaryExtraction(String response) {
    try {
      final cleaned = _cleanJsonResponse(response);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return DiaryExtractionData.fromJson(json);
    } catch (e) {
      return DiaryExtractionData();
    }
  }

  MealExtractionData _parseMealExtraction(String response) {
    try {
      final cleaned = _cleanJsonResponse(response);
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return MealExtractionData.fromJson(json);
    } catch (e) {
      return MealExtractionData();
    }
  }

  /// Strip markdown code fences and whitespace from LLM JSON responses
  String _cleanJsonResponse(String response) {
    String cleaned = response.trim();
    // Remove markdown code fences
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    return cleaned.trim();
  }
}

final extractionServiceProvider = Provider<ExtractionService>((ref) {
  final llm = ref.read(llmServiceProvider);
  return ExtractionService(llm);
});
