import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

import '../haptic_service.dart';

/// Concrete [HapticService] using Flutter's [HapticFeedback] for UI events
/// and the `vibration` package for custom denomination patterns.
class FlutterHapticService implements HapticService {
  /// Vibration patterns (ms) keyed by denomination code.
  /// Format: [delay, vibrate, delay, vibrate, …]
  static const Map<String, List<int>> _denominationPatterns = {
    'IDR_1000': [0, 100],
    'IDR_2000': [0, 100, 100, 100],
    'IDR_5000': [0, 100, 100, 100, 100, 100],
    'IDR_10000': [0, 200],
    'IDR_20000': [0, 200, 150, 200],
    'IDR_50000': [0, 300],
    'IDR_100000': [0, 300, 150, 300],
    'USD_1': [0, 80],
    'USD_5': [0, 80, 80, 80],
    'USD_10': [0, 80, 80, 80, 80, 80],
    'USD_20': [0, 120],
    'USD_50': [0, 120, 100, 120],
    'USD_100': [0, 200, 150, 200, 150, 200],
  };

  @override
  Future<void> selectionClick() => HapticFeedback.selectionClick();

  @override
  Future<void> lightImpact() => HapticFeedback.lightImpact();

  @override
  Future<void> mediumImpact() => HapticFeedback.mediumImpact();

  @override
  Future<void> heavyImpact() => HapticFeedback.heavyImpact();

  @override
  Future<void> denominationPattern(String denominationCode) async {
    final pattern = _denominationPatterns[denominationCode];
    if (pattern == null) {
      await mediumImpact();
      return;
    }
    final canVibrate = await Vibration.hasVibrator() ?? false;
    if (canVibrate) {
      await Vibration.vibrate(pattern: pattern);
    }
  }

  @override
  Future<void> success() async {
    final canVibrate = await Vibration.hasVibrator() ?? false;
    if (canVibrate) {
      await Vibration.vibrate(pattern: [0, 80, 80, 150]);
    }
  }

  @override
  Future<void> error() async {
    final canVibrate = await Vibration.hasVibrator() ?? false;
    if (canVibrate) {
      await Vibration.vibrate(duration: 400);
    }
  }
}
