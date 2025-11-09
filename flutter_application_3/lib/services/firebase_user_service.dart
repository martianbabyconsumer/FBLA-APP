import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save user profile data
  Future<void> saveUserProfile({
    required String userId,
    required String displayName,
    required String email,
    String? username,
    String? profileImagePath,
    String? bio,
    String? event,
    String? chapter,
    String? grade,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'displayName': displayName,
        'email': email,
        'username': username,
        'profileImagePath': profileImagePath,
        'bio': bio,
        'event': event,
        'chapter': chapter,
        'grade': grade,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user profile: $e');
      rethrow;
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Update display name
  Future<void> updateDisplayName(String userId, String displayName) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating display name: $e');
      rethrow;
    }
  }

  // Update username
  Future<void> updateUsername(String userId, String username) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'username': username,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating username: $e');
      rethrow;
    }
  }

  // Update profile image path
  Future<void> updateProfileImage(String userId, String? profileImagePath) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'profileImagePath': profileImagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating profile image: $e');
      rethrow;
    }
  }

  // Save user settings
  Future<void> saveUserSettings({
    required String userId,
    required bool autoSaveOnLike,
    required bool likeNotifications,
    required bool commentNotifications,
    required bool profileIsPublic,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).collection('settings').doc('preferences').set({
        'autoSaveOnLike': autoSaveOnLike,
        'likeNotifications': likeNotifications,
        'commentNotifications': commentNotifications,
        'profileIsPublic': profileIsPublic,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user settings: $e');
      rethrow;
    }
  }

  // Get user settings
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user settings: $e');
      return null;
    }
  }
}
