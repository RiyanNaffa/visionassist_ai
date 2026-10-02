import 'package:flutter/material.dart';

/// App color palette — high-contrast black/yellow/white, WCAG AA compliant.
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color primary = Color(0xFFFFD700); // gold-yellow
  static const Color onPrimary = Color(0xFF000000);
  static const Color onBackground = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFFF4444);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFAAAAAA);
  static const Color border = Color(0xFF333333);
}

/// Paths to bundled audio cue assets.
class AppAudioAssets {
  AppAudioAssets._();

  static const String beep = 'assets/audio/beep.mp3';
  static const String success = 'assets/audio/success.mp3';
  static const String modeSwitch = 'assets/audio/mode_switch.mp3';
  static const String error = 'assets/audio/error.mp3';
}
