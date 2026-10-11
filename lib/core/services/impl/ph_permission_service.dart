import 'package:permission_handler/permission_handler.dart' as ph;

import '../permission_service.dart';

/// `permission_handler`-backed [PermissionService].
class PhPermissionService implements PermissionService {
  @override
  Future<PermissionStatus> request(AppPermission permission) async {
    final status = await _resolve(permission).request();
    return _map(status);
  }

  @override
  Future<PermissionStatus> check(AppPermission permission) async {
    final status = await _resolve(permission).status;
    return _map(status);
  }

  @override
  Future<void> openSettings() => ph.openAppSettings();

  // ── Private helpers ───────────────────────────────────────────────────────

  ph.Permission _resolve(AppPermission permission) {
    switch (permission) {
      case AppPermission.camera:
        return ph.Permission.camera;
      case AppPermission.microphone:
        return ph.Permission.microphone;
      case AppPermission.speechRecognition:
        return ph.Permission.speech;
    }
  }

  PermissionStatus _map(ph.PermissionStatus status) {
    if (status.isGranted) return PermissionStatus.granted;
    if (status.isPermanentlyDenied) return PermissionStatus.permanentlyDenied;
    if (status.isRestricted) return PermissionStatus.restricted;
    return PermissionStatus.denied;
  }
}
