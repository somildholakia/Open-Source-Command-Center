import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../core/config/app_config.dart';

/// Owns the [Firebase] app lifecycle and tracks initialization state.
///
/// This service is the single entry point for `Firebase.initializeApp()`. All
/// other Firebase-facing services depend on the [isInitialized] flag exposed
/// here so they can degrade gracefully when configuration is missing (for
/// example, when `google-services.json` has not been provided yet).
class FirebaseService {
  FirebaseService._();

  /// Global singleton.
  static final FirebaseService instance = FirebaseService._();

  final Completer<FirebaseApp> _appCompleter = Completer<FirebaseApp>();
  bool _initializationStarted = false;
  Object? _initializationError;
  FirebaseApp? _initializedApp;

  /// True after [initialize] has been called and Firebase is ready to use.
  bool get isInitialized =>
      _appCompleter.isCompleted && _initializationError == null;

  /// The error captured during initialization, if any.
  Object? get initializationError => _initializationError;

  /// Initializes the default [FirebaseApp].
  ///
  /// Safe to call multiple times — only the first call performs work. Returns
  /// the resulting [FirebaseApp] on success, or `null` when initialization
  /// already failed. Callers that need to wait until Firebase is ready should
  /// use [appFuture].
  Future<FirebaseApp?> initialize() async {
    if (_initializationStarted) {
      if (_initializedApp != null) {
        return _initializedApp;
      }
      if (_initializationError != null) {
        return null;
      }
      try {
        await _appCompleter.future;
        return _initializedApp;
      } catch (_) {
        return null;
      }
    }
    _initializationStarted = true;

    try {
      final app = await Firebase.initializeApp();
      _initializedApp = app;
      if (!_appCompleter.isCompleted) {
        _appCompleter.complete(app);
      }
      if (AppConfig.enableVerboseFirebaseLogging) {
        debugPrint(
          '[FirebaseService] Initialized project: ${app.options.projectId}',
        );
      }
      return app;
    } catch (error, stackTrace) {
      _initializationError = error;
      if (!_appCompleter.isCompleted) {
        _appCompleter.completeError(error, stackTrace);
      }
      debugPrint(
        '[FirebaseService] Initialization failed: $error\n'
        'This is expected in development until a real Firebase project is '
        'configured. The app will continue to run with Firebase-backed '
        'features disabled.',
      );
      return null;
    }
  }

  /// Resolves with the default [FirebaseApp] once initialization completes.
  ///
  /// Completes with an error if initialization failed. Consumers that wish to
  /// stay tolerant should check [isInitialized] before awaiting this future.
  Future<FirebaseApp> get appFuture => _appCompleter.future;

  /// Returns the initialized [FirebaseApp], or `null` when Firebase has not
  /// been initialized (or failed to initialize).
  FirebaseApp? get app => _initializedApp;
}
