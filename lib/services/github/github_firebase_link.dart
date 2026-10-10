import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../firebase/firebase_service.dart';

/// Links/unlinks a GitHub identity to the app's Firebase Auth account.
///
/// The application identity remains the Firebase (email/password) user;
/// GitHub is attached as a **connected provider** via `linkWithCredential`.
/// This lets Firebase store/refresh the GitHub OAuth token and keeps provider
/// data separable from the app account.
///
/// When Firebase or the GitHub provider is not configured (external setup —
/// see docs/GITHUB_SETUP.md), operations report `false` and the app degrades
/// gracefully to token-only connection.
abstract class GitHubFirebaseLinker {
  /// Links the GitHub identity for [token] to the current Firebase user.
  /// Returns false when linking is unavailable.
  Future<bool> linkWithGitHubToken(String token);

  /// Removes the GitHub provider link from the current Firebase user.
  /// Returns false when unlinking is unavailable.
  Future<bool> unlinkGitHub();
}

class FirebaseGitHubLinker implements GitHubFirebaseLinker {
  const FirebaseGitHubLinker();

  FirebaseAuth? get _auth {
    final service = FirebaseService.instance;
    if (!service.isInitialized) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> linkWithGitHubToken(String token) async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (auth == null || user == null) return false;

    final alreadyLinked = user.providerData.any(
      (info) => info.providerId == 'github.com',
    );
    if (alreadyLinked) return true;

    try {
      final credential = GithubAuthProvider.credential(token);
      await user.linkWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      // credential-already-in-use: the GitHub identity belongs to another
      // Firebase account — connection still works token-only; surfaced via
      // debug logging only.
      debugPrint('[GitHubLink] link failed: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('[GitHubLink] link failed: $e');
      return false;
    }
  }

  @override
  Future<bool> unlinkGitHub() async {
    final auth = _auth;
    final user = auth?.currentUser;
    if (auth == null || user == null) return false;
    try {
      await user.unlink('github.com');
      return true;
    } on FirebaseAuthException catch (e) {
      // no-such-provider: nothing linked; treat as success.
      if (e.code == 'no-such-provider') return true;
      debugPrint('[GitHubLink] unlink failed: ${e.code}');
      return false;
    } catch (e) {
      debugPrint('[GitHubLink] unlink failed: $e');
      return false;
    }
  }
}
