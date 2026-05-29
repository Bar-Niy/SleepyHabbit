import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:sleepy_habbit/core/services/llm_service.dart';
import 'package:sleepy_habbit/core/services/voice_service.dart';
import 'package:sleepy_habbit/core/services/database_service.dart';
import 'package:sleepy_habbit/core/database/tables.dart';

enum InterviewState { idle, speaking, listening, processing, waitingForInput, complete }

class InterviewMessage {
  final String role;
  final String content;
  final DateTime timestamp;

  InterviewMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class InterviewData {
  final InterviewState state;
  final List<InterviewMessage> messages;
  final String sessionId;
  final int questionCount;

  InterviewData({
    this.state = InterviewState.idle,
    this.messages = const [],
    String? sessionId,
    this.questionCount = 0,
  }) : sessionId = sessionId ?? const Uuid().v4();

  InterviewData copyWith({
    InterviewState? state,
    List<InterviewMessage>? messages,
    int? questionCount,
  }) {
    return InterviewData(
      state: state ?? this.state,
      messages: messages ?? this.messages,
      sessionId: sessionId,
      questionCount: questionCount ?? this.questionCount,
    );
  }
}

class InterviewNotifier extends Notifier<InterviewData> {
  late final LlmService _llm;
  late final VoiceService _voice;

  @override
  InterviewData build() {
    _llm = ref.read(llmServiceProvider);
    _voice = ref.read(voiceServiceProvider);
    return InterviewData();
  }

  Future<void> startInterview() async {
    state = InterviewData(
      state: InterviewState.processing,
      messages: [],
    );

    // Initialize voice service
    await _voice.initialize();

    // Get first question from LLM
    final question = await _llm.generateMorningQuestion();

    final messages = [
      InterviewMessage(role: 'assistant', content: question),
    ];

    state = state.copyWith(
      messages: messages,
      state: InterviewState.speaking,
    );

    // Speak the question
    await _voice.speak(question);

    state = state.copyWith(state: InterviewState.waitingForInput);

    // Store in conversation DB
    await _saveMessage('assistant', question);
  }

  Future<void> startListening() async {
    state = state.copyWith(state: InterviewState.listening);

    String transcribedText = '';

    await _voice.startListening(
      onResult: (text) {
        transcribedText = text;
      },
      onDone: () async {
        if (transcribedText.isNotEmpty) {
          await _processUserResponse(transcribedText);
        } else {
          state = state.copyWith(state: InterviewState.waitingForInput);
        }
      },
    );
  }

  Future<void> stopListening() async {
    await _voice.stopListening();
  }

  Future<void> _processUserResponse(String userText) async {
    // Add user message
    final updatedMessages = [
      ...state.messages,
      InterviewMessage(role: 'user', content: userText),
    ];

    state = state.copyWith(
      messages: updatedMessages,
      state: InterviewState.processing,
    );

    await _saveMessage('user', userText);

    // Check if we should ask more or wrap up (max 5 questions)
    if (state.questionCount >= 4) {
      await _wrapUp();
      return;
    }

    // Get next question from LLM
    final conversationHistory = updatedMessages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final nextQuestion = await _llm.generateMorningQuestion(
      conversationHistory: conversationHistory,
    );

    final finalMessages = [
      ...updatedMessages,
      InterviewMessage(role: 'assistant', content: nextQuestion),
    ];

    state = state.copyWith(
      messages: finalMessages,
      state: InterviewState.speaking,
      questionCount: state.questionCount + 1,
    );

    await _voice.speak(nextQuestion);
    await _saveMessage('assistant', nextQuestion);

    state = state.copyWith(state: InterviewState.waitingForInput);
  }

  Future<void> skipQuestion() async {
    if (state.questionCount >= 4) {
      await _wrapUp();
      return;
    }

    state = state.copyWith(
      state: InterviewState.processing,
      questionCount: state.questionCount + 1,
    );

    final conversationHistory = state.messages
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final nextQuestion = await _llm.generateMorningQuestion(
      conversationHistory: conversationHistory,
    );

    final updatedMessages = [
      ...state.messages,
      InterviewMessage(role: 'assistant', content: nextQuestion),
    ];

    state = state.copyWith(
      messages: updatedMessages,
      state: InterviewState.speaking,
    );

    await _voice.speak(nextQuestion);
    await _saveMessage('assistant', nextQuestion);

    state = state.copyWith(state: InterviewState.waitingForInput);
  }

  Future<void> finishInterview() async {
    await _wrapUp();
  }

  Future<void> _wrapUp() async {
    // Save sleep entry with all collected data
    final fullTranscription = state.messages
        .map((m) => '${m.role}: ${m.content}')
        .join('\n');

    // Get LLM summary
    final summary = await _llm.chat(messages: [
      {
        'role': 'system',
        'content':
            'Summarize this morning sleep interview in 2-3 sentences. Focus on sleep quality, mood, and any notable dreams.'
      },
      {'role': 'user', 'content': fullTranscription},
    ]);

    // Store in database
    final db = DatabaseService.instance.database;
    await db.sleepEntryDao.insertEntry(
      SleepEntriesCompanion(
        date: Value(DateTime.now()),
        wakeTime: Value(DateTime.now()),
        transcription: Value(fullTranscription),
        llmSummary: Value(summary),
      ),
    );

    state = state.copyWith(state: InterviewState.complete);
  }

  Future<void> _saveMessage(String role, String content) async {
    final db = DatabaseService.instance.database;
    await db.into(db.conversationMessages).insert(
          ConversationMessagesCompanion(
            sessionId: Value(state.sessionId),
            sessionType: const Value('morning_interview'),
            role: Value(role),
            content: Value(content),
          ),
        );
  }
}

final interviewProvider =
    NotifierProvider<InterviewNotifier, InterviewData>(() {
  return InterviewNotifier();
});
