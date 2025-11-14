import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_user_service.dart';

class UserProvider extends ChangeNotifier {
  String _displayName = 'John Doe';
  String _email = 'john.doe@example.com';
  String? _username;
  String? _profileImagePath;
  String? _currentUserId;
  String _bio = '';
  String _event = '';
  String _chapter = '';
  String _grade = '';
  
  final FirebaseUserService _firebaseService = FirebaseUserService();

  String get displayName => _displayName;
  String get email => _email;
  String? get username => _username;
  String? get profileImagePath => _profileImagePath;
  String get bio => _bio;
  String get event => _event;
  String get chapter => _chapter;
  String get grade => _grade;

  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  UserProvider() {
    _loadUserData();
  }
  
  /// Set the current user ID for Firebase operations
  void setUserId(String? userId) {
    _currentUserId = userId;
    if (userId != null) {
      _loadFromFirebase(userId);
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _displayName = prefs.getString('displayName') ?? 'John Doe';
    _email = prefs.getString('email') ?? 'john.doe@example.com';
    _profileImagePath = prefs.getString('profileImagePath');
    _username = prefs.getString('username');
    _bio = prefs.getString('bio') ?? '';
    _event = prefs.getString('event') ?? '';
    _chapter = prefs.getString('chapter') ?? '';
    _grade = prefs.getString('grade') ?? '';
    notifyListeners();
  }
  
  /// Load user data from Firebase
  Future<void> _loadFromFirebase(String userId) async {
    try {
      final data = await _firebaseService.getUserProfile(userId);
      if (data != null) {
        _displayName = data['displayName'] ?? _displayName;
        _email = data['email'] ?? _email;
        _username = data['username'];
        _profileImagePath = data['profileImagePath'];
        _bio = data['bio'] ?? '';
        _event = data['event'] ?? '';
        _chapter = data['chapter'] ?? '';
        _grade = data['grade'] ?? '';
        
        // Also save to SharedPreferences for offline access
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('displayName', _displayName);
        await prefs.setString('email', _email);
        if (_username != null) await prefs.setString('username', _username!);
        if (_profileImagePath != null) await prefs.setString('profileImagePath', _profileImagePath!);
        await prefs.setString('bio', _bio);
        await prefs.setString('event', _event);
        await prefs.setString('chapter', _chapter);
        await prefs.setString('grade', _grade);
        
        notifyListeners();
      }
    } catch (e) {
      print('Error loading from Firebase: $e');
    }
  }
  
  /// Save user data to Firebase
  Future<void> _saveToFirebase() async {
    if (_currentUserId == null) return;
    
    try {
      await _firebaseService.saveUserProfile(
        userId: _currentUserId!,
        displayName: _displayName,
        email: _email,
        username: _username,
        profileImagePath: _profileImagePath,
        bio: _bio,
        event: _event,
        chapter: _chapter,
        grade: _grade,
      );
    } catch (e) {
      print('Error saving to Firebase: $e');
    }
  }

  Future<void> updateDisplayName(String name) async {
    final trimmed = name.trim();
    if (!RegExp(r'[a-zA-Z]').hasMatch(trimmed)) throw FormatException('Display name needs to have at least 1 letter');
    if (trimmed.isEmpty) throw FormatException('Display name cannot be empty');
    if (trimmed.length < 2) throw FormatException('Display name must be at least 2 characters');
    if (trimmed.length > 50) throw FormatException('Display name must be 50 characters or less');

    _displayName = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName', _displayName);
    
    // Save to Firebase
    await _saveToFirebase();
    
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
    
    // Save to Firebase
    await _saveToFirebase();
    
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

  Future<void> updateProfileImage(String? imagePath, {String? userEmail}) async {
    print('DEBUG UserProvider: updateProfileImage called');
    print('DEBUG UserProvider: imagePath = $imagePath');
    print('DEBUG UserProvider: userEmail = $userEmail');
    
    _profileImagePath = imagePath;
    final prefs = await SharedPreferences.getInstance();
    
    // Save both with and without email key for backward compatibility
    if (imagePath != null) {
      await prefs.setString('profileImagePath', imagePath);
      if (userEmail != null) {
        await prefs.setString('profileImagePath:$userEmail', imagePath);
      }
    } else {
      await prefs.remove('profileImagePath');
      if (userEmail != null) {
        await prefs.remove('profileImagePath:$userEmail');
      }
    }
    
    // Save to Firebase
    await _saveToFirebase();
    
    print('DEBUG UserProvider: _profileImagePath is now: $_profileImagePath');
    notifyListeners();
  }
  
  /// Load user data for a specific email (called after sign in)
  Future<void> loadUserDataForEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load saved profile image for this email (from SharedPreferences)
    final savedProfileImage = prefs.getString('profileImagePath:$email');
    if (savedProfileImage != null) {
      _profileImagePath = savedProfileImage;
      await prefs.setString('profileImagePath', savedProfileImage);
    }
    
    // Load saved username (already stored globally)
    _username = prefs.getString('username');
    
    notifyListeners();
  }
  
  /// Update profile data from Firebase Auth user
  void updateFromFirebaseUser(dynamic firebaseUser) {
    if (firebaseUser != null) {
      // Update profile image from Firebase photoURL if available
      if (firebaseUser.photoURL != null && firebaseUser.photoURL!.isNotEmpty) {
        _profileImagePath = firebaseUser.photoURL;
      }
      notifyListeners();
    }
  }

  Future<void> saveSettings(String displayName, String email, {String? username}) async {
    await updateDisplayName(displayName);
    await updateEmail(email);
    if (username != null) await updateUsername(username);
  }
  
  Future<void> updateBio(String bio) async {
    if (bio.length > 500) throw FormatException('Bio must be 500 characters or less');
    _bio = bio.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bio', _bio);
    await _saveToFirebase();
    notifyListeners();
  }
  
  Future<void> updateEvent(String event) async {
    if (event.trim().isEmpty) throw FormatException('Event cannot be empty');
    _event = event.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('event', _event);
    await _saveToFirebase();
    notifyListeners();
  }
  
  Future<void> updateChapter(String chapter) async {
    if (chapter.trim().isEmpty) throw FormatException('Chapter cannot be empty');
    _chapter = chapter.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chapter', _chapter);
    await _saveToFirebase();
    notifyListeners();
  }
  
  Future<void> updateGrade(String grade) async {
    final validGrades = ['9', '10', '11', '12', 'Grad'];
    if (!validGrades.contains(grade)) {
      throw FormatException('Grade must be one of: 9, 10, 11, 12, or Grad');
    }
    _grade = grade;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('grade', _grade);
    await _saveToFirebase();
    notifyListeners();
  }
}
