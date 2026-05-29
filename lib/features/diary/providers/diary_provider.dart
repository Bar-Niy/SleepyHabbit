import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sleepy_habbit/core/services/llm_service.dart';
import 'package:sleepy_habbit/core/services/voice_service.dart';
import 'package:sleepy_habbit/core/services/extraction_service.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

enum DiaryState { idle, speaking, listening, processing, complete }

class DiaryMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  DiaryMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class DiaryData {
  final DiaryState state;
  final List<DiaryMessage> messages;
  final String sessionId;
  final double progress;

  DiaryData({
    this.state = DiaryState.idle,
    this.messages = const [],
    String? sessionId,
    this.progress = 0.0,
  }) : sessionId = sessionId ?? const Uuid().v4();

  DiaryData copyWith({
    DiaryState? state,
    List<DiaryMessage>? messages,
    double? progress,
  }) {
    return DiaryData(
      state: state ?? this.state,
      messages: messages ?? this.messages,
      sessionId: sessionId,
      progress: progress ?? this.progress,
    );
  }
}

class DiaryNotifier extends Notifier<DiaryData> {
  late final LlmService _llm;
  late final VoiceService _voice;
  late final ExtractionService _extraction;
  static const int _maxExchanges = 6; // 6 back-and-forth exchanges

  @override
  DiaryData build() {
    _llm = ref.read(llmServiceProvider);
    _voice = ref.read(voiceServiceProvider);
    _extraction = ref.read(extractionServiceProvider);
    return DiaryData();
  }

  Future<void> startDiarySession() async {
    state = DiaryData(state: DiaryState.processing);
    await _voice.initialize();

    // Get opening prompt from LLM
    final prompt = await _llm.generateEveningPrompt();

    final messages = [
      DiaryMessage(role: 'assistant', content: prompt),
    ];

    state = state.copyWith(
      messages: messages,
      state: DiaryState.speaking,
      progress: 0.1,
    );

    await _voice.speak(prompt);
    await _saveMessage('assistant', prompt);

    state = state.copyWith(state: DiaryState.idle);
  }

  Future<void> startListening() async {
    state = state.copyWith(state: DiaryState.listening);

    String transcribed = '';
    await _voice.startListening(
      onResult: (text) {
        transcribed = text;
      },
      onDone: () async {
        if (transcribed.isNotEmpty) {
          await _processResponse(transcribed);
        } else {
          state = state.copyWith(state: DiaryState.idle);
        }
      },
      listenFor: const Duration(seconds: 60), // Longer for diary
    );
  }

  Future<void> stopListening() async {
    await _voice.stopListening();
  }

  Future<void> _processResponse(String userText) async {
    final updatedMessages = [
      ...state.messages,
      DiaryMessage(role: 'user', content: userText),
    ];

    final userExchanges =
        updatedMessages.where((m) => m.role == 'user').length;
    final progress = (userExchanges / _maxExchanges).clamp(0.0, 1.0);

    state = state.copyWith(
      messages: updatedMessages,
      state: DiaryState.processing,
      progress: progress,
    );

    await _saveMessage('user', userText);

    // Check if we should wrap up
    if (userExchanges >= _maxExchanges) {
      await finishSession();
      return;
    }

    // Get next prompt
    final history = updatedMessages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final nextPrompt = await _llm.generateEveningPrompt(
      conversationHistory: history,
    );

    final finalMessages = [
      ...updatedMessages,
      DiaryMessage(role: 'assistant', content: nextPrompt),
    ];

    state = state.copyWith(
      messages: finalMessages,
      state: DiaryState.speaking,
    );

    await _voice.speak(nextPrompt);
    await _saveMessage('assistant', nextPrompt);

    state = state.copyWith(state: DiaryState.idle);
  }

  Future<void> finishSession() async {
    if (state.messages.isEmpty) return;

    final fullTranscription = state.messages
        .map((m) => '${m.role}: ${m.content}')
        .join('\n');

    // Get summary from LLM
    final summary = await _llm.chat(messages: [
      {
        'role': 'system',
        'content':
            'Summarize this evening diary session. Extract key themes, mood, stressors, and gratitude points. Keep it concise (3-4 sentences).'
      },
      {'role': 'user', 'content': fullTranscription},
    ]);

    // Extract structured data
    final extracted = await _extraction.extractDiaryData(fullTranscription);

    // Store diary entry with structured data
    final db = DatabaseService.instance.database;
    await db.diaryEntryDao.insertEntry(
      DiaryEntriesCompanion(
        date: Value(DateTime.now()),
        transcription: Value(fullTranscription),
        llmSummary: Value(summary),
        mood: Value(extracted.mood),
        stressors: Value(jsonEncode(extracted.stressors)),
        gratitude: Value(jsonEncode(extracted.gratitudeItems)),
        tomorrowIntentions: Value(extracted.tomorrowIntentions),
        overallDayRating: Value(extracted.overallDayRating),
      ),
    );

    state = state.copyWith(state: DiaryState.complete, progress: 1.0);
  }

  Future<void> _saveMessage(String role, String content) async {
    final db = DatabaseService.instance.database;
    await db.into(db.conversationMessages).insert(
          ConversationMessagesCompanion(
            sessionId: Value(state.sessionId),
            sessionType: const Value('evening_diary'),
            role: Value(role),
            content: Value(content),
          ),
        );
  }
}

final diaryProvider = NotifierProvider<DiaryNotifier, DiaryData>(() {
  return DiaryNotifier();
});
