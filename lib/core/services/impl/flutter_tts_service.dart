import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../config/app_config.dart';
import '../tts_service.dart';

/// [FlutterTts]-backed [TtsService] with a sentence queue and pause/resume.
///
/// The engine runs in "await speak completion" mode, so each
/// `FlutterTts.speak` call returns only when its sentence is done, stopped or
/// paused. One loop speaks the queue a sentence at a time; [stop] bumps
/// [_generation], which retires that loop. Nothing else moves the queue —
/// so a late callback from an interrupted sentence can no longer cut off,
/// skip or silence the next one.
class FlutterTtsService implements TtsService {
  FlutterTtsService({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  final List<String> _sentenceQueue = [];
  bool _speaking = false;
  bool _paused = false;
  int _currentIndex = 0;

  /// Incremented by [stop]; a queue loop started under an older value quits.
  int _generation = 0;

  Future<void>? _ready;

  @override
  bool get isSpeaking => _speaking && !_paused;

  @override
  bool get isPaused => _paused;

  /// Configures the TTS engine. Safe to call more than once; speech waits
  /// for it, so the first sentence never goes out with the wrong settings.
  Future<void> initialize() => _ready ??= _configure();

  Future<void> _configure() async {
    try {
      // Must come first: the queue relies on speak() returning at completion.
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage(AppConfig.defaultLocale);
      await _tts.setSpeechRate(AppConfig.ttsSpeechRate);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      _tts.setErrorHandler((message) => debugPrint('[TTS] Error: $message'));
    } catch (e) {
      // Speak with engine defaults rather than not at all.
      debugPrint('[TTS] Configuration failed: $e');
    }
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
      unawaited(_speakQueue(_generation));
    }
  }

  @override
  Future<void> pause() async {
    if (!_speaking || _paused) return;
    _paused = true;
    // Ends the current speak() call; the queue loop sees _paused and waits.
    await _tts.pause();
  }

  @override
  Future<void> resume() async {
    if (!_paused) return;
    _paused = false;
    // Re-speaking the same sentence lets the engine continue where it paused.
    unawaited(_speakQueue(_generation));
  }

  @override
  Future<void> stop() async {
    _generation++;
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

  /// Speaks the queue one sentence at a time until it is empty, or until
  /// [stop] (new generation) or [pause] interrupts it.
  Future<void> _speakQueue(int generation) async {
    await initialize();
    while (generation == _generation &&
        !_paused &&
        _currentIndex < _sentenceQueue.length) {
      await _speakSentence(_sentenceQueue[_currentIndex]);
      if (generation != _generation || _paused) return;
      _currentIndex++;
    }
    if (generation == _generation && !_paused) {
      _speaking = false;
      _sentenceQueue.clear();
      _currentIndex = 0;
    }
  }

  /// Speaks [sentence] and waits for the engine to finish it.
  ///
  /// The timeout is only a safety net: after an engine error the plugin never
  /// completes the call. It is generous and per sentence, and it is cancelled
  /// as soon as the sentence completes.
  Future<void> _speakSentence(String sentence) async {
    try {
      await _tts.speak(sentence).timeout(sentenceTimeout(sentence));
    } on TimeoutException {
      debugPrint('[TTS] Sentence never completed, moving on.');
      // Resets the engine so the next speak() is not ignored.
      await _tts.stop();
    }
  }

  /// Upper bound for speaking [sentence]: about 5 characters a second, well
  /// below normal speech (~13 a second at the default rate).
  @visibleForTesting
  static Duration sentenceTimeout(String sentence) =>
      Duration(seconds: 10, milliseconds: 200 * sentence.length);

  /// Splits [text] into sentences on `.`, `?`, `!`, `:`, `;`.
  List<String> _splitSentences(String text) {
    return text
        .split(RegExp(r'(?<=[.?!:;])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
