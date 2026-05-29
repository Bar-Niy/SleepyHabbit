import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum VoiceState { idle, listening, speaking }

/// Service for TTS (speaking questions) and STT (recording answers)
class VoiceService {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  
  bool _sttAvailable = false;
  VoiceState _state = VoiceState.idle;

  VoiceState get state => _state;

  Future<void> initialize() async {
    // TTS setup
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45); // Slightly slower for sleepy users
    await _tts.setVolume(0.8);
    await _tts.setPitch(1.0);

    // STT setup
    _sttAvailable = await _stt.initialize(
      onError: (error) {
        _state = VoiceState.idle;
      },
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          _state = VoiceState.idle;
        }
      },
    );
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    _state = VoiceState.speaking;
    await _tts.speak(text);
    await _tts.awaitSpeakCompletion(true);
    _state = VoiceState.idle;
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
    _state = VoiceState.idle;
  }

  /// Start listening and return transcribed text via callback
  Future<void> startListening({
    required Function(String text) onResult,
    required Function() onDone,
    Duration? listenFor,
  }) async {
    if (!_sttAvailable) {
      onResult('Speech recognition not available');
      onDone();
      return;
    }

    _state = VoiceState.listening;
    
    await _stt.listen(
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          _state = VoiceState.idle;
          onDone();
        }
      },
      listenFor: listenFor ?? const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _stt.stop();
    _state = VoiceState.idle;
  }

  /// Check if STT is available
  bool get isSttAvailable => _sttAvailable;

  /// Dispose resources
  Future<void> dispose() async {
    await _tts.stop();
    await _stt.stop();
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  return VoiceService();
});
