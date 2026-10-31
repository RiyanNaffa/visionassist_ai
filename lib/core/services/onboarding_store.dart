/// Abstract contract for remembering whether the spoken onboarding guide
/// has been finished (or skipped) on this device.
abstract class OnboardingStore {
  /// Whether the guide was already finished or skipped.
  Future<bool> isCompleted();

  /// Records that the guide was finished or skipped.
  Future<void> markCompleted();
}
