import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider with ChangeNotifier {
  static const String _autoSaveKey = 'auto_save_on_like';
  static const String _likeNotificationsKey = 'like_notifications';
  static const String _commentNotificationsKey = 'comment_notifications';
  static const String _profileVisibilityKey = 'profile_visibility_public';
  
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  
  bool _autoSaveOnLike = false;
  bool _likeNotifications = true;
  bool _commentNotifications = true;
  bool _profileIsPublic = true;

  bool get isInitialized => _isInitialized;
  bool get autoSaveOnLike => _autoSaveOnLike;
  bool get likeNotifications => _likeNotifications;
  bool get commentNotifications => _commentNotifications;
  bool get profileIsPublic => _profileIsPublic;

  AppSettingsProvider();

  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _autoSaveOnLike = _prefs?.getBool(_autoSaveKey) ?? false;
    _likeNotifications = _prefs?.getBool(_likeNotificationsKey) ?? true;
    _commentNotifications = _prefs?.getBool(_commentNotificationsKey) ?? true;
    _profileIsPublic = _prefs?.getBool(_profileVisibilityKey) ?? true;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> setAutoSaveOnLike(bool value) async {
    if (!_isInitialized) return;
    _autoSaveOnLike = value;
    await _prefs?.setBool(_autoSaveKey, value);
    notifyListeners();
  }

  Future<void> setLikeNotifications(bool value) async {
    if (!_isInitialized) return;
    _likeNotifications = value;
    await _prefs?.setBool(_likeNotificationsKey, value);
    notifyListeners();
  }

  Future<void> setCommentNotifications(bool value) async {
    if (!_isInitialized) return;
    _commentNotifications = value;
    await _prefs?.setBool(_commentNotificationsKey, value);
    notifyListeners();
  }

  Future<void> setProfileVisibility(bool isPublic) async {
    if (!_isInitialized) return;
    _profileIsPublic = isPublic;
    await _prefs?.setBool(_profileVisibilityKey, isPublic);
    notifyListeners();
  }
}
