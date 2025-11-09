import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_user_service.dart';

class AppSettingsProvider with ChangeNotifier {
  static const String _autoSaveKey = 'auto_save_on_like';
  static const String _likeNotificationsKey = 'like_notifications';
  static const String _commentNotificationsKey = 'comment_notifications';
  static const String _profileVisibilityKey = 'profile_visibility_public';
  
  SharedPreferences? _prefs;
  bool _isInitialized = false;
  String? _currentUserId;
  
  final FirebaseUserService _firebaseService = FirebaseUserService();
  
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
  
  /// Set the current user ID for Firebase operations
  void setUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null && _isInitialized) {
      _loadFromFirebase(userId);
    }
  }

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
  
  /// Load settings from Firebase
  Future<void> _loadFromFirebase(String userId) async {
    try {
      final data = await _firebaseService.getUserSettings(userId);
      if (data != null) {
        _autoSaveOnLike = data['autoSaveOnLike'] ?? _autoSaveOnLike;
        _likeNotifications = data['likeNotifications'] ?? _likeNotifications;
        _commentNotifications = data['commentNotifications'] ?? _commentNotifications;
        _profileIsPublic = data['profileIsPublic'] ?? _profileIsPublic;
        
        // Also save to SharedPreferences for offline access
        await _prefs?.setBool(_autoSaveKey, _autoSaveOnLike);
        await _prefs?.setBool(_likeNotificationsKey, _likeNotifications);
        await _prefs?.setBool(_commentNotificationsKey, _commentNotifications);
        await _prefs?.setBool(_profileVisibilityKey, _profileIsPublic);
        
        notifyListeners();
      }
    } catch (e) {
      print('Error loading settings from Firebase: $e');
    }
  }
  
  /// Save settings to Firebase
  Future<void> _saveToFirebase() async {
    if (_currentUserId == null) return;
    
    try {
      await _firebaseService.saveUserSettings(
        userId: _currentUserId!,
        autoSaveOnLike: _autoSaveOnLike,
        likeNotifications: _likeNotifications,
        commentNotifications: _commentNotifications,
        profileIsPublic: _profileIsPublic,
      );
    } catch (e) {
      print('Error saving settings to Firebase: $e');
    }
  }

  Future<void> setAutoSaveOnLike(bool value) async {
    if (!_isInitialized) return;
    _autoSaveOnLike = value;
    await _prefs?.setBool(_autoSaveKey, value);
    await _saveToFirebase();
    notifyListeners();
  }

  Future<void> setLikeNotifications(bool value) async {
    if (!_isInitialized) return;
    _likeNotifications = value;
    await _prefs?.setBool(_likeNotificationsKey, value);
    await _saveToFirebase();
    notifyListeners();
  }

  Future<void> setCommentNotifications(bool value) async {
    if (!_isInitialized) return;
    _commentNotifications = value;
    await _prefs?.setBool(_commentNotificationsKey, value);
    await _saveToFirebase();
    notifyListeners();
  }

  Future<void> setProfileVisibility(bool isPublic) async {
    if (!_isInitialized) return;
    _profileIsPublic = isPublic;
    await _prefs?.setBool(_profileVisibilityKey, isPublic);
    await _saveToFirebase();
    notifyListeners();
  }
}
