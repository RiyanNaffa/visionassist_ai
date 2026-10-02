/// Abstract contract for haptic feedback.
abstract class HapticService {
  /// Light tap — UI selection.
  Future<void> selectionClick();

  /// Light impact — mode switch.
  Future<void> lightImpact();

  /// Medium impact — capture.
  Future<void> mediumImpact();

  /// Heavy impact — error.
  Future<void> heavyImpact();

  /// Custom vibration pattern for a specific [denominationCode],
  /// e.g. 'IDR_20000'.
  ///
  /// Pattern: alternating wait/vibrate durations in milliseconds.
  Future<void> denominationPattern(String denominationCode);

  /// Short double-pulse for success events.
  Future<void> success();

  /// Long single-pulse for errors.
  Future<void> error();
}
