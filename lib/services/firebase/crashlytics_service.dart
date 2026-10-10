import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';
import 'firebase_service.dart';

/// Wrapper around [FirebaseCrashlytics].
///
/// Captures uncaught errors, logs non-fatal errors, and supports setting
/// a user identifier for debugging. Degrades safely when Crashlytics
/// is unavailable (`AppConfig.enableCrashlytics == false` or Firebase
/// has not been initialized).
class CrashlyticsService {
  CrashlyticsService._();

  /// Singleton.
  static final CrashlyticsService instance = CrashlyticsService._();

  /// The underlying Crashlytics instance, or `null` when unavailable.
  FirebaseCrashlytics? get crashlytics {
    if (AppConfig.enableCrashlytics && FirebaseService.instance.isInitialized) {
      return FirebaseCrashlytics.instance;
    }
    return null;
  }

  /// Initializes Crashlytics and hooks uncaught async errors.
  ///
  /// Call once during app startup (e.g. after `FirebaseService.initialize`).
  void initialize() {
    if (crashlytics == null) {
      debugPrint(
        '[CrashlyticsService] initialize skipped: Crashlytics unavailable',
      );
      return;
    }
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
      return true;
    };
    debugPrint('[CrashlyticsService] Crashlytics initialized');
  }

  /// Logs a non-fatal error with optional context.
  ///
  /// [reason] should describe what went wrong in user-facing terms.
  Future<void> logError(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    if (crashlytics == null) {
      if (AppConfig.enableVerboseFirebaseLogging) {
        debugPrint('[CrashlyticsService] logError skipped ($reason): $error');
      }
      return;
    }
    await crashlytics!.recordError(error, stackTrace, reason: reason);
  }

  /// Associates the current session with a user identifier (e.g., uid, email).
  ///
  /// Clears automatically when the app restarts; call again after sign-in.
  Future<void> setUserId(String? userId) async {
    if (crashlytics == null) return;
    await crashlytics!.setUserIdentifier(userId ?? 'anonymous');
  }

  /// Sets custom keys for debugging (visible in Crashlytics console).
  Future<void> setCustomKey(String key, Object value) async {
    if (crashlytics == null) return;
    await crashlytics!.setCustomKey(key, value);
  }
}
