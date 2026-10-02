import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../config/app_config.dart';
import '../tts_service.dart';

/// [FlutterTts]-backed [TtsService] with sentence-queue, pause/resume, and
/// timeout-based deadlock prevention.
class FlutterTtsService implements TtsService {
  FlutterTtsService() : _tts = FlutterTts();

  final FlutterTts _tts;
  final List<String> _sentenceQueue = [];
  bool _speaking = false;
  bool _paused = false;
  int _currentIndex = 0;

  /// Timeout before assuming a sentence will never complete.
  static const Duration _sentenceTimeout = Duration(seconds: 15);

  @override
  bool get isSpeaking => _speaking && !_paused;

  @override
  bool get isPaused => _paused;

  /// Initialises the TTS engine.  Call once before [speak].
  Future<void> initialize() async {
    await _tts.setLanguage(AppConfig.defaultLocale);
    await _tts.setSpeechRate(AppConfig.ttsSpeechRate);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(_onComplete);
    _tts.setCancelHandler(_onCancel);
    _tts.setErrorHandler((message) => _onError(message));
  }

  @override
  Future<void> speak(String text, {bool interrupt = false}) async {
    final sentences = _splitSentences(text);
    if (sentences.isEmpty) return;

    if (interrupt) {
      await stop();
    }

    _sentenceQueue.addAll(sentences);
    if (!_speaking) {
      _speaking = true;
      _paused = false;
      _currentIndex = _sentenceQueue.length - sentences.length;
      await _speakNext();
    }
  }

  @override
  Future<void> pause() async {
    if (!_speaking || _paused) return;
    _paused = true;
    await _tts.pause();
  }

  @override
  Future<void> resume() async {
    if (!_paused) return;
    _paused = false;
    // Restart from current sentence (pause doesn't guarantee mid-sentence
    // resume on all platforms).
    await _speakNext();
  }

  @override
  Future<void> stop() async {
    _speaking = false;
    _paused = false;
    _sentenceQueue.clear();
    _currentIndex = 0;
    await _tts.stop();
  }

  @override
  Future<void> setSpeechRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  @override
  Future<void> dispose() async {
    await stop();
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _speakNext() async {
    if (_paused || _currentIndex >= _sentenceQueue.length) {
      _speaking = false;
      _sentenceQueue.clear();
      _currentIndex = 0;
      return;
    }

    final sentence = _sentenceQueue[_currentIndex];

    // Timeout fallback — never deadlock waiting for a completion handler.
    Timer(_sentenceTimeout, () {
      if (_speaking && !_paused) {
        debugPrint('[TTS] Sentence timeout, advancing queue.');
        _onComplete();
      }
    });

    await _tts.speak(sentence);
  }

  void _onComplete() {
    if (!_speaking || _paused) return;
    _currentIndex++;
    _speakNext();
  }

  void _onCancel() {
    _speaking = false;
    _paused = false;
  }

  void _onError(dynamic message) {
    debugPrint('[TTS] Error: $message');
    _speaking = false;
    _paused = false;
  }

  /// Splits [text] into sentences on `.`, `?`, `!`, `:`, `;`.
  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.?!:;])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
