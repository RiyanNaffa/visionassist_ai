import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:visionassist_ai/core/services/impl/flutter_tts_service.dart';

/// Stands in for the plugin in "await speak completion" mode: speak() returns
/// only when the test finishes the sentence, or on stop() / pause().
class _FakeEngine implements FlutterTts {
  final List<String> spoken = [];
  int stops = 0;
  int pauses = 0;
  bool awaitsCompletion = false;

  /// The real plugin ignores a speak() while one is in flight.
  bool overlapped = false;

  Completer<dynamic>? _current;

  /// Completes the sentence being spoken, like the engine's onDone.
  void finish() => _end(1);

  void _end(int result) {
    final current = _current;
    _current = null;
    current?.complete(result);
  }

  @override
  Future<dynamic> speak(String text, {bool focus = false}) {
    if (_current != null) overlapped = true;
    spoken.add(text);
    final current = Completer<dynamic>();
    _current = current;
    return current.future;
  }

  @override
  Future<dynamic> stop() async {
    stops++;
    _end(0);
    return 1;
  }

  @override
  Future<dynamic> pause() async {
    pauses++;
    _end(0);
    return 1;
  }

  @override
  Future<dynamic> awaitSpeakCompletion(bool awaitCompletion) async {
    awaitsCompletion = awaitCompletion;
    return 1;
  }

  @override
  Future<dynamic> setLanguage(String language) async => 1;
  @override
  Future<dynamic> setSpeechRate(double rate) async => 1;
  @override
  Future<dynamic> setPitch(double pitch) async => 1;
  @override
  Future<dynamic> setVolume(double volume) async => 1;
  @override
  void setErrorHandler(ErrorHandler handler) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late _FakeEngine engine;
  late FlutterTtsService tts;

  setUp(() {
    engine = _FakeEngine();
    tts = FlutterTtsService(tts: engine);
  });

  test('turns on await-completion before the first sentence', () async {
    await tts.speak('Halo.');
    await settle();

    expect(engine.awaitsCompletion, isTrue);
    expect(engine.spoken, ['Halo.']);
  });

  test('speaks sentences one at a time, in order', () async {
    await tts.speak('Satu. Dua? Tiga!');
    await settle();
    expect(engine.spoken, ['Satu.']);
    expect(tts.isSpeaking, isTrue);

    for (var i = 0; i < 3; i++) {
      engine.finish();
      await settle();
    }

    expect(engine.spoken, ['Satu.', 'Dua?', 'Tiga!']);
    expect(tts.isSpeaking, isFalse);
    expect(engine.overlapped, isFalse);
  });

  test('without interrupt, new text waits for the current queue', () async {
    await tts.speak('Satu.');
    await tts.speak('Dua.');
    await settle();
    expect(engine.spoken, ['Satu.']);

    engine.finish();
    await settle();
    expect(engine.spoken, ['Satu.', 'Dua.']);
    expect(engine.stops, 0);
  });

  test('interrupt replaces the queue; the stopped sentence cannot advance it',
      () async {
    await tts.speak('A satu. A dua. A tiga.');
    await settle();

    await tts.speak('B satu. B dua.', interrupt: true);
    await settle();
    expect(engine.stops, 1);
    expect(engine.spoken, ['A satu.', 'B satu.']);

    engine.finish();
    await settle();
    engine.finish();
    await settle();

    expect(engine.spoken, ['A satu.', 'B satu.', 'B dua.']);
    expect(tts.isSpeaking, isFalse);
    expect(engine.overlapped, isFalse);
  });

  test('pause holds the sentence; resume speaks it again, then moves on',
      () async {
    await tts.speak('Satu. Dua.');
    await settle();

    await tts.pause();
    await settle();
    expect(engine.pauses, 1);
    expect(tts.isPaused, isTrue);
    expect(engine.spoken, ['Satu.']);

    await tts.resume();
    await settle();
    // The plugin continues a re-spoken sentence from where it paused.
    expect(engine.spoken, ['Satu.', 'Satu.']);

    engine.finish();
    await settle();
    expect(engine.spoken, ['Satu.', 'Satu.', 'Dua.']);
  });

  test('stop ends speech and clears the queue', () async {
    await tts.speak('Satu. Dua.');
    await settle();

    await tts.stop();
    await settle();

    expect(tts.isSpeaking, isFalse);
    expect(engine.spoken, ['Satu.']);
  });

  testWidgets('a finished sentence leaves no timer that cuts the next one',
      (tester) async {
    // Regression: every sentence used to start a 15 s timer that was never
    // cancelled, and it later "advanced" whatever sentence was playing.
    final long = 'Kalimat ${'panjang ' * 10}selesai.';
    expect(
      FlutterTtsService.sentenceTimeout(long),
      greaterThan(const Duration(seconds: 16)),
    );

    await tts.speak('Pendek. $long');
    await tester.pump();
    engine.finish();
    await tester.pump();
    expect(engine.spoken, ['Pendek.', long]);

    await tester.pump(const Duration(seconds: 16));
    expect(engine.spoken, ['Pendek.', long]);
    expect(engine.stops, 0);

    engine.finish();
    await tester.pump();
  });

  testWidgets('a sentence that never completes is skipped after its timeout',
      (tester) async {
    await tts.speak('Macet. Lanjut.');
    await tester.pump();
    expect(engine.spoken, ['Macet.']);

    await tester.pump(
      FlutterTtsService.sentenceTimeout('Macet.') + const Duration(seconds: 1),
    );
    expect(engine.stops, 1);
    expect(engine.spoken, ['Macet.', 'Lanjut.']);

    engine.finish();
    await tester.pump();
  });
}
