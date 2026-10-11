import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
import '../../core/services/impl/flutter_camera_service.dart';
import '../../core/services/service_providers.dart';
import '../controllers/home_controller.dart';
import '../widgets/mode_status_banner.dart';
import '../widgets/quadrant_button.dart';

/// The main application screen.
///
/// Adapts between:
/// - **Screen-reader mode** (`accessibleNavigation == true`): four large
///   quadrant buttons for Previous mode, Next mode, Capture, and Ask by voice.
/// - **Standard gesture mode**: swipe left/right, double-tap, long-press.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final accessible = MediaQuery.of(context).accessibleNavigation;

    if (!state.cameraPermissionGranted) {
      return _PermissionDeniedScreen(
        isPermanent: state.cameraPermissionPermanentlyDenied,
        onRetry: controller.requestCameraPermission,
        onSettings: controller.openSettings,
      );
    }

    final body = accessible
        ? _AccessibleLayout(state: state, controller: controller)
        : _GestureLayout(state: state, controller: controller);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: body),
    );
  }
}

// ── Camera preview widget ───────────────────────────────────────────────────

/// Renders the live [CameraPreview] if the controller is ready, otherwise
/// shows a loading indicator over a black background.
///
/// Watches [homeControllerProvider] for `cameraReady` so it rebuilds as soon
/// as [HomeController._initCamera] finishes.
class _LiveCameraPreview extends ConsumerWidget {
  const _LiveCameraPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch cameraReady so this widget rebuilds after camera initialises.
    final cameraReady = ref.watch(
      homeControllerProvider.select((s) => s.cameraReady),
    );

    if (!cameraReady) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final svc = ref.read(cameraServiceProvider);
    final cameraController =
        (svc is FlutterCameraService) ? svc.controller : null;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return Container(color: AppColors.background);
    }

    return CameraPreview(cameraController);
  }
}

// ── Gesture layout ──────────────────────────────────────────────────────────

class _GestureLayout extends StatelessWidget {
  const _GestureLayout({
    required this.state,
    required this.controller,
  });

  final HomeState state;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppStrings.semanticsCamera,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragEnd: (details) {
          final dx = details.primaryVelocity ?? 0;
          if (dx < -200) {
            controller.nextMode();
          } else if (dx > 200) {
            controller.previousMode();
          }
        },
        onTap: controller.onSingleTap,
        onDoubleTap: controller.onDoubleTap,
        onLongPress: controller.onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Live camera preview.
            const _LiveCameraPreview(),
            // Status overlay pinned to bottom.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ModeStatusBanner(state: state),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Accessible layout ───────────────────────────────────────────────────────

class _AccessibleLayout extends StatelessWidget {
  const _AccessibleLayout({
    required this.state,
    required this.controller,
  });

  final HomeState state;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Camera preview takes upper half.
        const Expanded(
          child: _LiveCameraPreview(),
        ),
        // Mode status banner.
        ModeStatusBanner(state: state),
        // Four quadrant buttons.
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                QuadrantButton(
                  label: AppStrings.btnPreviousMode,
                  semanticsHint: AppStrings.hintSwipeRight,
                  onPressed: controller.previousMode,
                  icon: Icons.arrow_back,
                ),
                QuadrantButton(
                  label: AppStrings.btnNextMode,
                  semanticsHint: AppStrings.hintSwipeLeft,
                  onPressed: controller.nextMode,
                  icon: Icons.arrow_forward,
                ),
                QuadrantButton(
                  label: AppStrings.btnCapture,
                  semanticsHint: AppStrings.hintDoubleTap,
                  onPressed: controller.onDoubleTap,
                  icon: Icons.camera_alt,
                ),
                QuadrantButton(
                  label: AppStrings.btnAskByVoice,
                  semanticsHint: AppStrings.hintLongPress,
                  onPressed: controller.onLongPress,
                  icon: Icons.mic,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Permission denied screen ────────────────────────────────────────────────

class _PermissionDeniedScreen extends StatelessWidget {
  const _PermissionDeniedScreen({
    required this.isPermanent,
    required this.onRetry,
    required this.onSettings,
  });

  final bool isPermanent;
  final VoidCallback onRetry;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: AppStrings.permissionCameraTitle,
                child: const Text(
                  AppStrings.permissionCameraTitle,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                label: AppStrings.permissionCameraMessage,
                child: const Text(
                  AppStrings.permissionCameraMessage,
                  style: TextStyle(
                    color: AppColors.onBackground,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              if (isPermanent)
                Semantics(
                  button: true,
                  label: AppStrings.permissionCameraSettings,
                  child: ElevatedButton(
                    onPressed: onSettings,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(72),
                    ),
                    child: const Text(AppStrings.permissionCameraSettings),
                  ),
                )
              else
                Semantics(
                  button: true,
                  label: AppStrings.permissionCameraRetry,
                  child: ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(72),
                    ),
                    child: const Text(AppStrings.permissionCameraRetry),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
