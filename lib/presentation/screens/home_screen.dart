import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_strings.dart';
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

// ── Gesture layout ─────────────────────────────────────────────────────────

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
            // Camera preview placeholder (replace with CameraPreview widget).
            Container(color: AppColors.background),
            // Status overlay.
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

// ── Accessible layout ─────────────────────────────────────────────────────

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
        Expanded(
          child: ModeStatusBanner(state: state),
        ),
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

// ── Permission denied screen ───────────────────────────────────────────────

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
                child: Text(
                  AppStrings.permissionCameraTitle,
                  style: const TextStyle(
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
                child: Text(
                  AppStrings.permissionCameraMessage,
                  style: const TextStyle(
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
