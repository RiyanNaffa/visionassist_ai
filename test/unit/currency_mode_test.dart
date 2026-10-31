import 'package:flutter_test/flutter_test.dart';
import 'package:visionassist_ai/core/constants/app_strings.dart';
import 'package:visionassist_ai/features/currency_detector/domain/entities/currency_detection.dart';

import '../helpers/home_controller_harness.dart';

const _note20k = DetectedBanknote(
  classLabel: '20000',
  confidence: 0.9,
  cx: 0.5,
  cy: 0.5,
  width: 0.4,
  height: 0.2,
);

/// Starts the app (guide already done, camera allowed) in the currency mode.
Future<HomeControllerHarness> _inCurrencyMode() async {
  final h = HomeControllerHarness(
    completed: true,
    granted: true,
    currencyDetector: FakeCurrencyDetector(isAvailable: true),
  );
  await h.start();
  await h.controller.nextMode();
  expect(h.state.modeIndex, 1);
  return h;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('announces a banknote while still in the currency mode', () async {
    final h = await _inCurrencyMode();

    h.camera.onFrame!(nv21Frame());
    // The frame is converted on another isolate before detection runs.
    await waitFor(() => h.currency.calls == 1);
    h.currency.respond([_note20k]);
    await settle();

    expect(h.tts.spoken.last, AppStrings.currencySpeech('20000'));
    expect(h.state.statusText, AppStrings.currencySpeech('20000'));
  });

  test('a detection that finishes after a mode switch stays silent', () async {
    final h = await _inCurrencyMode();

    h.camera.onFrame!(nv21Frame());
    await waitFor(() => h.currency.calls == 1);

    // The user swipes on while the frame is still being processed.
    await h.controller.nextMode();
    final modeAnnouncement = h.tts.spoken.last;
    h.currency.respond([_note20k]);
    await settle();

    expect(h.state.modeIndex, 2);
    expect(h.tts.spoken.last, modeAnnouncement);
    expect(h.tts.spoken, isNot(contains(AppStrings.currencySpeech('20000'))));
    expect(h.state.statusText, isEmpty);
  });

  test('frames are not processed outside the live modes', () async {
    final h = await _inCurrencyMode();
    await h.controller.nextMode();

    h.camera.onFrame!(nv21Frame());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(h.currency.calls, 0);
  });
}
