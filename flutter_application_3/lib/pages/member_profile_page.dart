import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/firebase_user_service.dart';
import '../repository/post_repository.dart';
import 'settings_page.dart';
import 'dart:io';

class MemberProfilePage extends StatefulWidget {
  final String userId;
  final bool isOwnProfile;

  const MemberProfilePage({
    Key? key,
    required this.userId,
    required this.isOwnProfile,
  }) : super(key: key);

  @override
  State<MemberProfilePage> createState() => _MemberProfilePageState();
}

class _MemberProfilePageState extends State<MemberProfilePage> {
  final FirebaseUserService _firebaseService = FirebaseUserService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (widget.isOwnProfile) {
      // If it's the user's own profile, use UserProvider data
      setState(() {
        _isLoading = false;
      });
    } else {
      // First check if this is a bot profile
      final botProfile = InMemoryPostRepository.getBotProfile(widget.userId);
      
      if (botProfile != null) {
        // Use bot profile data directly
        print('DEBUG: Using bot profile data for ${widget.userId}');
        if (mounted) {
          setState(() {
            _profileData = botProfile;
            _isLoading = false;
          });
        }
      } else {
        // Load profile data from Firebase for real users
        try {
          final data = await _firebaseService.getUserProfile(widget.userId);
          print('DEBUG: Loaded profile data for ${widget.userId}:');
          print('DEBUG: displayName: ${data?['displayName']}');
          print('DEBUG: username: ${data?['username']}');
          print('DEBUG: bio: ${data?['bio']}');
          print('DEBUG: Full data: $data');
          if (mounted) {
            setState(() {
              _profileData = data;
              _isLoading = false;
            });
          }
        } catch (e) {
          print('Error loading profile: $e');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    
    // Use UserProvider for own profile, otherwise use loaded data
    final displayName = widget.isOwnProfile 
        ? userProvider.displayName 
        : (_profileData?['displayName'] as String? ?? 'User');
    final username = widget.isOwnProfile
        ? userProvider.username
        : (_profileData?['username'] as String?);
    final profileImagePath = widget.isOwnProfile
        ? userProvider.profileImagePath
        : (_profileData?['profileImagePath'] as String?);
    final bio = widget.isOwnProfile
        ? userProvider.bio
        : (_profileData?['bio'] as String? ?? '');
    final event = widget.isOwnProfile
        ? userProvider.event
        : (_profileData?['event'] as String? ?? '');
    final chapter = widget.isOwnProfile
        ? userProvider.chapter
        : (_profileData?['chapter'] as String? ?? '');
    final grade = widget.isOwnProfile
        ? userProvider.grade
        : (_profileData?['grade'] as String? ?? '');
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.isOwnProfile ? 'My Profile' : 'Member Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Profile Picture and Name
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
              child: Column(
                children: [
                  // Profile Picture
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF003366),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 57,
                      backgroundColor: const Color(0xFFE3F2FD),
                      backgroundImage: profileImagePath != null &&
                              profileImagePath.isNotEmpty
                          ? FileImage(File(profileImagePath))
                          : null,
                      child: profileImagePath == null ||
                              profileImagePath.isEmpty
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF003366),
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Display Name
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Username
                  Text(
                    (username != null && username.isNotEmpty)
                        ? '@$username'
                        : '@user',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.isOwnProfile) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SettingsPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit Profile'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tags Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tags',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (event.isNotEmpty)
                        _buildTag(
                          icon: Icons.event,
                          label: event,
                          color: const Color(0xFF1976D2),
                        ),
                      if (chapter.isNotEmpty)
                        _buildTag(
                          icon: Icons.group,
                          label: chapter,
                          color: const Color(0xFF388E3C),
                        ),
                      if (grade.isNotEmpty)
                        _buildTag(
                          icon: Icons.school,
                          label: 'Grade $grade',
                          color: const Color(0xFF7B1FA2),
                        ),
                    ],
                  ),
                  if (event.isEmpty &&
                      chapter.isEmpty &&
                      grade.isEmpty)
                    Text(
                      'No tags added yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Bio Section
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bio',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003366),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    bio.isNotEmpty
                        ? bio
                        : 'No bio added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: bio.isNotEmpty
                          ? Colors.black87
                          : Colors.grey[600],
                      fontStyle: bio.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
