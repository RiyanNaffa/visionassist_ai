/// Permissions the app requires.
enum AppPermission { camera, microphone, speechRecognition }

/// Status of a single permission.
enum PermissionStatus { granted, denied, permanentlyDenied, restricted }

/// Abstract contract for runtime-permission management.
abstract class PermissionService {
  /// Requests the given [permission] and returns its new [PermissionStatus].
  Future<PermissionStatus> request(AppPermission permission);

  /// Returns the current [PermissionStatus] without showing a dialog.
  Future<PermissionStatus> check(AppPermission permission);

  /// Opens the OS application-settings screen so the user can manually
  /// change permanently-denied permissions.
  Future<void> openSettings();
}
