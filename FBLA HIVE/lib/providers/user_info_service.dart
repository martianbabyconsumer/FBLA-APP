import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

/// Service to get current user display info (display name, username)
/// This allows user profile changes to reflect across all their activity
class UserInfoService {
  final AuthService _authService;
  
  UserInfoService(this._authService);
  
  /// Get display name for a given userId
  /// If userId matches current user, returns their current display name from Firebase
  Future<String> getDisplayName(String? userId) async {
    if (userId == null) return 'Unknown User';
    
    // If this is the current user, get their latest display name
    if (_authService.user?.uid == userId) {
      return _authService.displayName;
    }
    
    // For other users, we'd fetch from Firestore in a real app
    // For now, return a placeholder
    return 'User';
  }
  
  /// Get username for a given userId
  /// If userId matches current user, returns their current username from SharedPreferences
  Future<String> getUsername(String? userId) async {
    if (userId == null) return '@unknown';
    
    // If this is the current user, get their latest username
    if (_authService.user?.uid == userId) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('username');
        return username != null ? '@$username' : '@user';
      } catch (_) {
        return '@user';
      }
    }
    
    // For other users, we'd fetch from Firestore in a real app
    // For now, return a placeholder
    return '@user';
  }
  
  /// Get both display name and username together
  Future<UserDisplayInfo> getUserInfo(String? userId) async {
    final displayName = await getDisplayName(userId);
    final username = await getUsername(userId);
    return UserDisplayInfo(displayName: displayName, username: username);
  }
  
  /// Check if the given userId is the current logged-in user
  bool isCurrentUser(String? userId) {
    if (userId == null) return false;
    return _authService.user?.uid == userId;
  }
}

class UserDisplayInfo {
  final String displayName;
  final String username;
  
  UserDisplayInfo({required this.displayName, required this.username});
}
