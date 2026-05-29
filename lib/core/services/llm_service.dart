import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// LLM Service that supports both local (llama.cpp server) and remote API backends.
/// Default: local llama.cpp running on device via companion process.
/// Fallback: Ollama, Groq, or OpenAI-compatible API.
///
/// NETWORK SECURITY NOTE:
/// This service is the ONLY component that makes cleartext HTTP requests.
/// - Default URL (localhost:8080) stays on-device — no network at all.
/// - Local network URLs (192.168.x.x) use cleartext HTTP because home
///   LLM servers don't have TLS certificates.
/// - Public URLs (Groq, OpenAI, etc.) should use HTTPS — the user is
///   responsible for entering https:// URLs for external services.
/// - Google Drive backup uses the Google SDK which enforces HTTPS.
///
/// The network_security_config.xml allows cleartext specifically for this use case.
class LlmService {
  final Dio _dio;
  String _baseUrl;
  String? _apiKey;
  String _model;

  LlmService({
    String baseUrl = 'http://localhost:8080',
    String? apiKey,
    String model = 'llama3.2',
  })  : _baseUrl = baseUrl,
        _apiKey = apiKey,
        _model = model,
        _dio = Dio();

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('llm_base_url') ?? _baseUrl;
    _apiKey = prefs.getString('llm_api_key') ?? _apiKey;
    _model = prefs.getString('llm_model') ?? _model;
  }

  Future<void> saveSettings({
    required String baseUrl,
    String? apiKey,
    required String model,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('llm_base_url', baseUrl);
    if (apiKey != null) await prefs.setString('llm_api_key', apiKey);
    await prefs.setString('llm_model', model);
    _baseUrl = baseUrl;
    _apiKey = apiKey;
    _model = model;
  }

  /// Generate a response from the LLM given conversation history.
  /// Uses OpenAI-compatible chat completions API format.
  Future<String> chat({
    required List<Map<String, String>> messages,
    double temperature = 0.7,
    int maxTokens = 500,
  }) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/v1/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            if (_apiKey != null) 'Authorization': 'Bearer $_apiKey',
          },
        ),
        data: jsonEncode({
          'model': _model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );

      final data = response.data;
      return data['choices'][0]['message']['content'] as String;
    } catch (e) {
      return _getFallbackResponse(messages);
    }
  }

  /// Generate morning interview questions based on context
  Future<String> generateMorningQuestion({
    List<Map<String, String>> conversationHistory = const [],
    String? previousSleepData,
  }) async {
    final systemPrompt = '''You are a caring sleep coach and morning companion. 
Your job is to gently interview the user after they wake up to understand their sleep quality.
Ask about:
- How they slept (quality, duration, interruptions)
- How they're feeling right now (energy, mood)
- Whether they remember any dreams
- Any physical sensations (headache, stiffness, refreshed)

Keep questions warm, concise, and conversational. Ask ONE question at a time.
If this is the first question, start with a gentle "Good morning!" greeting.
${previousSleepData != null ? 'Recent sleep context: $previousSleepData' : ''}''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...conversationHistory,
    ];

    return chat(messages: messages);
  }

  /// Generate evening diary prompts
  Future<String> generateEveningPrompt({
    List<Map<String, String>> conversationHistory = const [],
    String? todaysMeals,
    String? todaysActivities,
  }) async {
    final systemPrompt = '''You are a calming evening companion helping the user wind down.
Your goal is to help them "offload" their thoughts before sleep - like a diary or telling a partner about the day.
Research shows this prevents racing thoughts and improves sleep quality.

Guide them through:
- What happened today (highlights and lowlights)
- How they're feeling emotionally
- Any worries or unresolved thoughts
- Things they're grateful for
- Intentions or hopes for tomorrow

Be warm, empathetic, and non-judgmental. Ask ONE question at a time.
Help them feel heard and validated.
${todaysMeals != null ? 'Today\'s meals: $todaysMeals' : ''}
${todaysActivities != null ? 'Today\'s activities: $todaysActivities' : ''}''';

    final messages = [
      {'role': 'system', 'content': systemPrompt},
      ...conversationHistory,
    ];

    return chat(messages: messages);
  }

  /// Analyze sleep patterns over time
  Future<String> analyzeSleepPatterns({
    required String sleepDataJson,
    required String diaryDataJson,
    required String mealDataJson,
  }) async {
    final messages = [
      {
        'role': 'system',
        'content': '''You are a sleep analysis expert. Analyze the user's sleep data, 
diary entries, and meal patterns to identify factors that may be affecting their sleep quality.
Look for correlations between:
- Late meals and poor sleep
- Stressful days and sleep quality
- Exercise/activity and sleep
- Patterns in dream content
- Mood trends
Provide actionable, personalized insights.'''
      },
      {
        'role': 'user',
        'content':
            'Here is my data:\n\nSleep: $sleepDataJson\n\nDiary: $diaryDataJson\n\nMeals: $mealDataJson\n\nWhat patterns do you see?'
      },
    ];

    return chat(messages: messages, maxTokens: 1000);
  }

  /// Fallback response when LLM is unavailable
  String _getFallbackResponse(List<Map<String, String>> messages) {
    final lastUserMessage =
        messages.lastWhere((m) => m['role'] == 'user', orElse: () => {});
    if (lastUserMessage.isEmpty) {
      return 'Good morning! How did you sleep last night?';
    }
    // Simple rule-based fallback
    return 'Thank you for sharing that. Could you tell me more about how that made you feel?';
  }
}

final llmServiceProvider = Provider<LlmService>((ref) {
  return LlmService();
});
