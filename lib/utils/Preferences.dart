import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static Future<SharedPreferences> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await _getPrefs();
      return prefs.getBool(_hasSeenOnboardingKey) ?? false;
    } catch (e) {
      print('Error reading onboarding status: $e');
      return false; // Default to false if there's an error
    }
  }

  static Future<void> setOnboardingSeen() async {
    try {
      final prefs = await _getPrefs();
      await prefs.setBool(_hasSeenOnboardingKey, true);
    } catch (e) {
      print('Error setting onboarding status: $e');
    }
  }
}
