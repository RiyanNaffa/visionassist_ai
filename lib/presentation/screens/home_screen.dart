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
import '../widgets/swipe_detector.dart';

/// The main application screen.
///
/// Adapts between:
/// - **Screen-reader mode** (`accessibleNavigation == true`): four large
///   quadrant buttons for Previous mode, Next mode, Capture, and Ask by voice.
/// - **Standard gesture mode**: swipe left/right, double-tap, long-press.
///
/// While the spoken guide runs, [_OnboardingScreen] replaces both layouts.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final accessible = MediaQuery.of(context).accessibleNavigation;

    if (state.isOnboarding) {
      return _OnboardingScreen(
        state: state,
        controller: controller,
        accessible: accessible,
      );
    }

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
      child: SwipeDetector(
        onSwipeLeft: controller.nextMode,
        onSwipeRight: controller.previousMode,
        // Swipe up replays the spoken guide.
        onSwipeUp: controller.startOnboarding,
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
        // Replays the spoken guide (swipe up in gesture mode).
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: SizedBox(
            width: double.infinity,
            child: QuadrantButton(
              label: AppStrings.btnGuide,
              semanticsHint: AppStrings.hintSwipeUp,
              onPressed: controller.startOnboarding,
              icon: Icons.help_outline,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Onboarding (spoken guide) ───────────────────────────────────────────────

/// Shows the step being spoken in large text, for low-vision users.
///
/// Gesture mode mirrors the main screen: swipe left = next, swipe right =
/// back, tap = repeat, double tap = skip (or start, on the last step).
/// With a screen reader the same actions are buttons.
class _OnboardingScreen extends StatelessWidget {
  const _OnboardingScreen({
    required this.state,
    required this.controller,
    required this.accessible,
  });

  final HomeState state;
  final HomeController controller;
  final bool accessible;

  @override
  Widget build(BuildContext context) {
    final steps = AppStrings.onboardingSteps(screenReader: accessible);
    final step = state.onboardingStep.clamp(0, steps.length - 1);
    final isLast = step == steps.length - 1;

    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.onboardingProgress(step + 1, steps.length),
            style: const TextStyle(color: AppColors.muted, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                steps[step],
                style: const TextStyle(
                  color: AppColors.onBackground,
                  fontSize: 24,
                  height: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (accessible)
            _OnboardingButtons(controller: controller, isLast: isLast)
          else
            const Text(
              AppStrings.onboardingGestureHint,
              style: TextStyle(color: AppColors.primary, fontSize: 16),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: accessible
            ? content
            : SwipeDetector(
                onSwipeLeft: controller.onboardingNext,
                onSwipeRight: controller.onboardingPrevious,
                onTap: controller.onboardingRepeat,
                onDoubleTap: controller.finishOnboarding,
                child: content,
              ),
      ),
    );
  }
}

/// Screen-reader controls for the guide: back, next / start, and skip.
class _OnboardingButtons extends StatelessWidget {
  const _OnboardingButtons({required this.controller, required this.isLast});

  final HomeController controller;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Equal-height buttons that grow with their labels, so large system
        // font sizes wrap instead of overflowing.
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: QuadrantButton(
                  label: AppStrings.btnOnboardingPrevious,
                  semanticsHint: AppStrings.hintOnboardingPrevious,
                  onPressed: controller.onboardingPrevious,
                  icon: Icons.arrow_back,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: QuadrantButton(
                  label: isLast
                      ? AppStrings.btnOnboardingStart
                      : AppStrings.btnOnboardingNext,
                  semanticsHint: isLast
                      ? AppStrings.hintOnboardingStart
                      : AppStrings.hintOnboardingNext,
                  onPressed: controller.onboardingNext,
                  icon: isLast ? Icons.check : Icons.arrow_forward,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) ...[
          const SizedBox(height: 8),
          QuadrantButton(
            label: AppStrings.btnOnboardingSkip,
            semanticsHint: AppStrings.hintOnboardingSkip,
            onPressed: controller.finishOnboarding,
            icon: Icons.skip_next,
          ),
        ],
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
        child: Center(
          // Scrolls instead of overflowing at large system font sizes.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
      ),
    );
  }
}
