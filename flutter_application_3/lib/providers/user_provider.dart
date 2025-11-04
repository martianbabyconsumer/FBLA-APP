import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProvider extends ChangeNotifier {
  String _displayName = 'John Doe';
  String _email = 'john.doe@example.com';
  String? _username;
  String? _profileImagePath;

  String get displayName => _displayName;
  String get email => _email;
  String? get username => _username;
  String? get profileImagePath => _profileImagePath;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  UserProvider() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('displayName') ?? 'John Doe';
    _email = prefs.getString('email') ?? 'john.doe@example.com';
    _profileImagePath = prefs.getString('profileImagePath');
    _username = prefs.getString('username');
    notifyListeners();
  }

  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw FormatException('Display name cannot be empty');
    if (trimmed.length < 2) throw FormatException('Display name must be at least 2 characters');
    if (trimmed.length > 50) throw FormatException('Display name must be 50 characters or less');
    if (!RegExp(r'[a-zA-Z]').hasMatch(trimmed)) throw FormatException('Display name must contain at least one letter');

    _displayName = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName', _displayName);
    notifyListeners();
  }

  Future<void> updateUsername(String username) async {
    final trimmed = username.trim();
    if (trimmed.isEmpty) throw FormatException('Username cannot be empty');
    if (!RegExp(r'^[a-zA-Z0-9_]{3,20}').hasMatch(trimmed)) {
      if (trimmed.length < 3 || trimmed.length > 20 || !RegExp(r'^[a-zA-Z0-9_]+').hasMatch(trimmed)) {
        throw FormatException('Username must be 3-20 characters and contain only letters, numbers or underscores');
      }
    }
    _username = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _username!);
    notifyListeners();
  }

  Future<void> updateEmail(String email) async {
    if (email.trim().isEmpty) return;
    if (!_emailRegex.hasMatch(email.trim())) throw FormatException('Invalid email format');
    _email = email.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', _email);
    notifyListeners();
  }

  Future<void> updateProfileImage(String? imagePath) async {
    _profileImagePath = imagePath;
    final prefs = await SharedPreferences.getInstance();
    if (imagePath != null) {
      await prefs.setString('profileImagePath', imagePath);
    } else {
      await prefs.remove('profileImagePath');
    }
    notifyListeners();
  }

  Future<void> saveSettings(String displayName, String email, {String? username}) async {
    await updateDisplayName(displayName);
    await updateEmail(email);
    if (username != null) await updateUsername(username);
  }
}
