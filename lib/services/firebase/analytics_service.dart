import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import 'firebase_service.dart';

/// Wrapper around [FirebaseAnalytics].
///
/// Logs screen views, custom events, and user properties. Degrades to
/// no-ops when Firebase Analytics has not been initialized or is disabled
/// (`AppConfig.enableAnalytics == false`).
class AnalyticsService {
  AnalyticsService._();

  /// Singleton.
  static final AnalyticsService instance = AnalyticsService._();

  /// The underlying analytics instance, or `null` when unavailable.
  FirebaseAnalytics? get analytics {
    if (AppConfig.enableAnalytics && FirebaseService.instance.isInitialized) {
      return FirebaseAnalytics.instance;
    }
    return null;
  }

  /// Logs a screen view with the given screen name.
  ///
  /// No-op when analytics is unavailable.
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    if (analytics == null) {
      if (AppConfig.enableVerboseFirebaseLogging) {
        debugPrint('[AnalyticsService] logScreenView skipped ($screenName)');
      }
      return;
    }
    await analytics!.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  /// Logs a custom event.
  ///
  /// [parameters] are optional key-value pairs (values must be allowed
  /// analytics param types).
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    if (analytics == null) return;
    try {
      await analytics!.logEvent(name: name, parameters: parameters);
    } catch (e) {
      debugPrint('[AnalyticsService] logEvent($name) failed: $e');
    }
  }

  /// Sets a user property for the current signed-in user.
  ///
  /// No-op if analytics unavailable.
  Future<void> setUserProperty(String name, String? value) async {
    if (analytics == null) return;
    await analytics!.setUserProperty(name: name, value: value);
  }

  /// Clears all user properties and resets session data.
  ///
  /// Useful when signing out.
  Future<void> resetAnalytics() async {
    if (analytics == null) return;
    await analytics!.resetAnalyticsData();
  }
}
