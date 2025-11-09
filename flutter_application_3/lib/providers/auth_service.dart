import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Sign up with email and password
  Future<String?> signUp({
    required String email,
    required String password,
    required String displayName,
    String? username,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(displayName);
      await credential.user?.reload();
      _user = _auth.currentUser;

      // Persist username and display name locally
      if (username != null && username.trim().isNotEmpty) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('username:${username.trim()}', email.trim());
          // also save username for current user
          await prefs.setString('username', username.trim());
          // Save username mapped to user email for persistence
          await prefs.setString('username:${email.trim()}', username.trim());
        } catch (_) {}
      }
      
      // Save display name for this user's email
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('displayName:${email.trim()}', displayName);
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      switch (e.code) {
        case 'weak-password':
          return 'The password provided is too weak.';
        case 'email-already-in-use':
          return 'An account already exists for that email.';
        case 'invalid-email':
          return 'The email address is invalid.';
        default:
          return e.message ?? 'An error occurred during sign up.';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred.';
    }
  }

  // Sign in with email and password
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    // Backwards-compatible signature: caller may pass username in 'email' param.
    String identifier = email.trim();
    String? resolvedEmail;
    if (identifier.contains('@')) {
      resolvedEmail = identifier;
    } else {
      // Try resolve username -> email via SharedPreferences on this device
      try {
        final prefs = await SharedPreferences.getInstance();
        resolvedEmail = prefs.getString('username:${identifier}');
      } catch (_) {}
      if (resolvedEmail == null) {
        // No mapping found, treat as email to let Firebase return user-not-found
        resolvedEmail = identifier;
      }
    }
    try {
      _isLoading = true;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: resolvedEmail,
        password: password,
      );

      // Load previously saved user data for this email
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedDisplayName = prefs.getString('displayName:${resolvedEmail}');
        final savedUsername = prefs.getString('username:${resolvedEmail}');
        if (savedDisplayName != null && _auth.currentUser != null) {
          await _auth.currentUser!.updateDisplayName(savedDisplayName);
          await _auth.currentUser!.reload();
        }
        // Also restore username for current session
        if (savedUsername != null) {
          await prefs.setString('username', savedUsername);
        }
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return null; // Success
    } on FirebaseAuthException catch (e) {
      _isLoading = false;
      notifyListeners();

      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          return 'Either the username or password is wrong';
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-disabled':
          return 'This account has been disabled.';
        default:
          return e.message ?? 'An error occurred during sign in.';
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return 'An unexpected error occurred.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'The email address is invalid.';
        case 'user-not-found':
          return 'No user found for that email.';
        default:
          return e.message ?? 'An error occurred.';
      }
    } catch (e) {
      return 'An unexpected error occurred.';
    }
  }

  // Refresh user data and notify listeners
  Future<void> refreshUser() async {
    await _user?.reload();
    _user = _auth.currentUser;
    notifyListeners();
  }

  // Get current user display name
  String get displayName => _user?.displayName ?? 'User';

  // Get current user email
  String get email => _user?.email ?? '';
}
