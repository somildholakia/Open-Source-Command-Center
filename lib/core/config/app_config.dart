import 'package:flutter/foundation.dart';

/// App environment classification.
enum AppEnvironment { development, staging, production }

/// Centralized app configuration.
///
/// Holds environment detection, debug settings, and feature flags.
/// Firebase project identifiers and secrets are intentionally **not**
/// hardcoded here. They are provided by `google-services.json` (Android),
/// `GoogleService-Info.plist` (iOS), or `firebase_options.dart` (FlutterFire).
class AppConfig {
  AppConfig._();

  /// The current build environment, derived from `kReleaseMode` / `kDebugMode`
  /// and the `APP_ENV` `--dart-define`.
  ///
  /// Override at build time with:
  ///   flutter run --dart-define=APP_ENV=production
  ///   flutter build apk --dart-define=APP_ENV=staging
  static AppEnvironment get environment => _resolveEnvironment();

  /// True when the app is running in a debug build.
  static const bool isDebug = kDebugMode;

  /// True when the app is running in a release build.
  static const bool isRelease = kReleaseMode;

  /// True when the app is running in a profile build.
  static const bool isProfile = kProfileMode;

  /// True when running in development (default) or staging.
  static bool get isDevelopmentLike =>
      environment == AppEnvironment.development ||
      environment == AppEnvironment.staging;

  /// Verbose Firebase logging is enabled for non-release environments.
  static bool get enableVerboseFirebaseLogging => isDevelopmentLike;

  /// Feature flags. New flags must default to `false` and be flipped
  /// per environment once the feature is ready.
  static const bool enableAuthBackend = false;
  static const bool enableFirestoreBackend = false;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;

  static AppEnvironment _resolveEnvironment() {
    const fromDefine = String.fromEnvironment('APP_ENV', defaultValue: '');
    switch (fromDefine.toLowerCase()) {
      case 'production':
      case 'prod':
        return AppEnvironment.production;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'development':
      case 'dev':
      case '':
        return AppEnvironment.development;
      default:
        return AppEnvironment.development;
    }
  }

  /// Human-readable environment label, useful for logging and About screens.
  static String get environmentLabel {
    switch (environment) {
      case AppEnvironment.development:
        return 'Development';
      case AppEnvironment.staging:
        return 'Staging';
      case AppEnvironment.production:
        return 'Production';
    }
  }
}
