import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../onboarding_store.dart';

/// [SharedPreferences]-backed [OnboardingStore].
///
/// Storage errors never reach the user: a failed read counts as "not
/// completed", so at worst the guide is offered again.
class SharedPrefsOnboardingStore implements OnboardingStore {
  static const String _key = 'onboarding_completed';

  @override
  Future<bool> isCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (e) {
      debugPrint('[OnboardingStore] Read failed: $e');
      return false;
    }
  }

  @override
  Future<void> markCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (e) {
      debugPrint('[OnboardingStore] Write failed: $e');
    }
  }
}
