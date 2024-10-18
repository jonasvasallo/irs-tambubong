import 'package:shared_preferences/shared_preferences.dart';

class RateLimiter {
  final String userId;
  final String keyPrefix;  // To support different actions (e.g., comments, likes, etc.)
  final Duration cooldownDuration;

  RateLimiter({
    required this.userId,
    required this.keyPrefix,
    required this.cooldownDuration,
  });

  /// Checks if the action is allowed based on the cooldown period.
  Future<bool> isActionAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActionTimeString = prefs.getString('$keyPrefix$lastActionKeySuffix');

    if (lastActionTimeString == null) {
      return true; // No previous action, so it's allowed
    }

    final lastActionTime = DateTime.parse(lastActionTimeString);
    final currentTime = DateTime.now();
    final timeSinceLastAction = currentTime.difference(lastActionTime);

    return timeSinceLastAction >= cooldownDuration;
  }

  /// Updates the local timestamp to track the last action time.
  Future<void> updateLastActionTime() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTime = DateTime.now();
    await prefs.setString('$keyPrefix$lastActionKeySuffix', currentTime.toIso8601String());
  }

  /// Helper to create the shared preferences key
  String get lastActionKeySuffix => '_lastActionTime_$userId';
}
