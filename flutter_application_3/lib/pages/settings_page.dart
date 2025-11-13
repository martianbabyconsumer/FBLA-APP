import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../providers/auth_service.dart';
import '../providers/app_settings_provider.dart';
import '../repository/post_repository.dart';
import '../widgets/onboarding_tutorial.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _eventController = TextEditingController();
  final _chapterController = TextEditingController();
  String _selectedGrade = '';
  final ImagePicker _picker = ImagePicker();
  XFile? _webImage; // For web platform
  bool _enableNotifications = false;
  bool _showImagesInFeed = true;
  
  // Track connected social media accounts
  bool _facebookConnected = false;
  bool _twitterConnected = false;
  bool _instagramConnected = false;
  bool _linkedinConnected = false;

  @override
  void initState() {
    super.initState();
    // Load values from AuthService instead of UserProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = context.read<AuthService>();
      final userProvider = context.read<UserProvider>();
      
      // Get display name from Firebase Auth
      _displayNameController.text = authService.displayName;
      
      // Try to load username from SharedPreferences (saved during signup)
      SharedPreferences.getInstance().then((prefs) {
        final username = prefs.getString('username') ?? '';
        if (mounted) {
          setState(() {
            _usernameController.text = username;
          });
        }
      });
      
      // Load profile fields from UserProvider
      _bioController.text = userProvider.bio;
      _eventController.text = userProvider.event;
      _chapterController.text = userProvider.chapter;
      _selectedGrade = userProvider.grade;

      // For web, load the saved profile image path as _webImage if it exists
      if (kIsWeb && userProvider.profileImagePath != null) {
        setState(() {
          _webImage = XFile(userProvider.profileImagePath!);
        });
      }
    });
    // Load simple local preferences (does not need BuildContext)
    _loadLocalSettings();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _eventController.dispose();
    _chapterController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        final userProvider = context.read<UserProvider>();
        final authService = context.read<AuthService>();
        final postRepository = context.read<PostRepository>();

        if (kIsWeb) {
          // For web, store the XFile and save its path to provider
          setState(() {
            _webImage = image;
          });
          await userProvider.updateProfileImage(image.path, userEmail: authService.email);
        } else {
          // For mobile, store the path directly
          await userProvider.updateProfileImage(image.path, userEmail: authService.email);
        }

        // Save profile picture URL to Firebase Auth
        try {
          await authService.user?.updatePhotoURL(image.path);
          await authService.refreshUser();
        } catch (e) {
          print('Failed to update Firebase photoURL: $e');
        }

        // Update all existing posts and comments with new profile picture
        if (authService.user?.uid != null) {
          final username = userProvider.username;
          final handle = (username != null && username.isNotEmpty) ? '@$username' : '@you';
          print('DEBUG: Updating posts with profileImagePath: ${image.path}');
          print('DEBUG: User ID: ${authService.user!.uid}');
          print('DEBUG: Handle: $handle');
          print('DEBUG: Display Name: ${userProvider.displayName}');
          postRepository.updateUserInfo(
            authService.user!.uid, 
            handle, 
            userProvider.displayName,
            image.path, // Use the image path directly instead of userProvider.profileImagePath
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _loadLocalSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableNotifications = prefs.getBool('enableNotifications') ?? false;
      _showImagesInFeed = prefs.getBool('showImagesInFeed') ?? true;
      _facebookConnected = prefs.getBool('facebookConnected') ?? false;
      _twitterConnected = prefs.getBool('twitterConnected') ?? false;
      _instagramConnected = prefs.getBool('instagramConnected') ?? false;
      _linkedinConnected = prefs.getBool('linkedinConnected') ?? false;
    });
  }

  Future<void> _setEnableNotifications(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableNotifications', v);
    setState(() => _enableNotifications = v);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(v ? 'Notifications enabled' : 'Notifications disabled')),
    );
  }

  Future<void> _setShowImagesInFeed(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showImagesInFeed', v);
    setState(() => _showImagesInFeed = v);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(v ? 'Feed images enabled' : 'Feed images hidden')),
    );
  }

  Widget _buildProfileImage(UserProvider userProvider) {
    // For web, show the picked image or FBLA logo
    if (kIsWeb) {
      if (_webImage != null) {
        return Image.network(
          _webImage!.path,
          key: ValueKey(_webImage!.path),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFBLALogo(100);
          },
        );
      } else {
        return _buildFBLALogo(100);
      }
    } else {
      // For mobile, use file path from provider
      if (userProvider.profileImagePath != null) {
        return Image.file(
          File(userProvider.profileImagePath!),
          key: ValueKey(userProvider.profileImagePath),
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFBLALogo(100);
          },
        );
      } else {
        return _buildFBLALogo(100);
      }
    }
  }

  Widget _buildFBLALogo(double size) {
    final theme = Theme.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          'FBLA',
          style: TextStyle(
            color: theme.colorScheme.onPrimary,
            fontSize: size / 6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Future<void> _clearProfileImage() async {
    final userProvider = context.read<UserProvider>();
    final authService = context.read<AuthService>();
    final postRepository = context.read<PostRepository>();
    
    await userProvider.updateProfileImage(null, userEmail: authService.email);
    setState(() {
      _webImage = null;
    });
    
    // Remove profile picture from Firebase Auth
    try {
      await authService.user?.updatePhotoURL(null);
      await authService.refreshUser();
    } catch (e) {
      print('Failed to update Firebase photoURL: $e');
    }
    
    // Update all existing posts and comments with removed profile picture
    if (authService.user?.uid != null) {
      final username = userProvider.username;
      final handle = (username != null && username.isNotEmpty) ? '@$username' : '@you';
      postRepository.updateUserInfo(
        authService.user!.uid, 
        handle, 
        userProvider.displayName,
        null, // Remove profile image from all posts/comments
      );
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture cleared')));
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setDialogState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: currentPasswordController,
                    obscureText: obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureCurrentPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureCurrentPassword = !obscureCurrentPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureNewPassword = !obscureNewPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscureConfirmPassword = !obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Password must be at least 6 characters',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final currentPassword = currentPasswordController.text.trim();
                  final newPassword = newPasswordController.text.trim();
                  final confirmPassword = confirmPasswordController.text.trim();

                  // Validation - show snackbar but keep dialog open
                  if (currentPassword.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your current password')),
                    );
                    return;
                  }

                  if (newPassword.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a new password')),
                    );
                    return;
                  }

                  if (newPassword.length < 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New password must be at least 6 characters')),
                    );
                    return;
                  }

                  if (newPassword != confirmPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('New passwords do not match'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  if (currentPassword == newPassword) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('New password must be different from current password')),
                    );
                    return;
                  }

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  // Attempt to change password
                  final authService = context.read<AuthService>();
                  final error = await authService.changePassword(
                    currentPassword: currentPassword,
                    newPassword: newPassword,
                  );

                  // Close loading indicator
                  if (context.mounted) Navigator.of(context).pop();

                  if (context.mounted) {
                    if (error == null) {
                      // Close password dialog
                      Navigator.of(dialogContext).pop(true);
                      
                      // Show verification email sent dialog with auto-check
                      await showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (verifyDialogContext) {
                          // Start checking for email verification
                          Future.delayed(const Duration(seconds: 2)).then((_) async {
                            while (verifyDialogContext.mounted) {
                              await authService.refreshUser();
                              if (authService.isEmailVerified) {
                                if (verifyDialogContext.mounted) {
                                  Navigator.of(verifyDialogContext).pop(true);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Email verified successfully! 🎉'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                                break;
                              }
                              await Future.delayed(const Duration(seconds: 3));
                            }
                          });

                          return WillPopScope(
                            onWillPop: () async {
                              // Show confirmation dialog before allowing back navigation
                              final shouldExit = await showDialog<bool>(
                                context: verifyDialogContext,
                                builder: (context) => AlertDialog(
                                  title: const Text('Skip Verification?'),
                                  content: const Text(
                                    'Your email is not verified yet. You can verify it later from settings, but some features may be limited.\n\nAre you sure you want to skip?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Continue Waiting'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Skip Verification'),
                                    ),
                                  ],
                                ),
                              );
                              return shouldExit ?? false;
                            },
                            child: AlertDialog(
                              title: const Row(
                                children: [
                                  Icon(Icons.mark_email_read, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text('Check Your Email'),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Your password has been updated successfully!'),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'We\'ve sent a verification link to your email. Click the link to verify.',
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: const Text(
                                      'This dialog will close automatically when you click the link. Check spam/junk folder if needed.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Waiting for verification...',
                                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.lock, size: 16, color: Colors.orange.shade700),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Text(
                                            'You must verify to continue. Use back button to skip.',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    final error = await authService.resendVerificationEmail();
                                    if (verifyDialogContext.mounted) {
                                      if (error == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Verification email sent!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(error)),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Resend Email'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    } else {
                      // Show error but keep password dialog open
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Change Password'),
              ),
            ],
          );
        },
      ),
    );

    // Clean up controllers
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _saveSettings() async {
    final authService = context.read<AuthService>();
    final postRepository = context.read<PostRepository>();
    final userProvider = context.read<UserProvider>();
    
    try {
      final newDisplayName = _displayNameController.text.trim();
      final newUsername = _usernameController.text.trim();
      
      // Update Firebase display name if changed
      if (newDisplayName.isNotEmpty && newDisplayName != authService.displayName) {
        await authService.user?.updateDisplayName(newDisplayName);
        await authService.refreshUser();
      }

      // Save username to SharedPreferences
      if (newUsername.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', newUsername);
        // Also update the mapping from username to email for login
        await prefs.setString('username:$newUsername', authService.email);
        // Save username mapped to email for persistence
        await prefs.setString('username:${authService.email}', newUsername);
      }
      
      // Save display name mapped to email for persistence
      if (newDisplayName.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('displayName:${authService.email}', newDisplayName);
      }

      // Update UserProvider with new values
      if (newDisplayName.isNotEmpty) {
        await userProvider.updateDisplayName(newDisplayName);
      }
      if (newUsername.isNotEmpty) {
        await userProvider.updateUsername(newUsername);
      }

      // Update all existing posts and comments by this user
      if (authService.user?.uid != null) {
        final newHandle = newUsername.isNotEmpty ? '@$newUsername' : '@you';
        final displayName = newDisplayName.isNotEmpty ? newDisplayName : authService.displayName;
        postRepository.updateUserInfo(authService.user!.uid, newHandle, displayName, userProvider.profileImagePath);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _saveProfileInfo() async {
    final userProvider = context.read<UserProvider>();
    
    try {
      final bio = _bioController.text.trim();
      final event = _eventController.text.trim();
      final chapter = _chapterController.text.trim();
      final grade = _selectedGrade;

      // Validate required fields
      if (event.isEmpty || chapter.isEmpty || grade.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please fill in all required fields (Event, Chapter, Grade)'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Update UserProvider
      await userProvider.updateBio(bio);
      await userProvider.updateEvent(event);
      await userProvider.updateChapter(chapter);
      await userProvider.updateGrade(grade);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile information saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile info: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _resetProfileFields() async {
    final authService = context.read<AuthService>();
    
    try {
      // Reset display name to default
      await authService.user?.updateDisplayName('User');
      await authService.user?.reload();
      
      // Clear username
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('username');

      // Reload controllers
      _displayNameController.text = authService.displayName;
      _usernameController.text = '';

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile fields reset to defaults')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to reset: $e')));
      }
    }
  }

  Future<void> _resetTheme() async {
    final themeProvider = context.read<ThemeProvider>();
    
    try {
      // Reset theme color to Blue and ensure light mode
      await themeProvider.setColor('Blue');
      if (themeProvider.isDarkMode) await themeProvider.toggleTheme();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Theme reset to default (Light, Blue)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to reset theme: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<UserProvider, AuthService>(
      builder: (context, userProvider, authService, _) {
        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
              // Profile Picture Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipOval(child: _buildProfileImage(userProvider)),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(authService.displayName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(authService.email,
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withAlpha(179))),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              IconButton(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.camera_alt)),
                              TextButton(
                                  onPressed: _clearProfileImage,
                                  child: const Text('Clear')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      // Display name field (editable)
                      TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.alternate_email),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          ElevatedButton.icon(
                              onPressed: _saveSettings,
                              icon: const Icon(Icons.save),
                              label: const Text('Save')),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                              onPressed: _resetProfileFields,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reset')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Profile Information Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Profile Information',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      // Bio
                      TextField(
                        controller: _bioController,
                        maxLines: 4,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Bio',
                          hintText: 'Tell us about yourself...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.info_outline),
                          helperText: 'Max 500 characters',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Event
                      TextField(
                        controller: _eventController,
                        decoration: const InputDecoration(
                          labelText: 'Event *',
                          hintText: 'e.g., Business Presentation',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.event),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Chapter
                      TextField(
                        controller: _chapterController,
                        decoration: const InputDecoration(
                          labelText: 'Chapter *',
                          hintText: 'e.g., Mountain View High',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.group),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Grade Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedGrade.isEmpty ? null : _selectedGrade,
                        decoration: const InputDecoration(
                          labelText: 'Grade *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.school),
                        ),
                        hint: const Text('Select your grade'),
                        items: const [
                          DropdownMenuItem(value: '9', child: Text('Grade 9')),
                          DropdownMenuItem(value: '10', child: Text('Grade 10')),
                          DropdownMenuItem(value: '11', child: Text('Grade 11')),
                          DropdownMenuItem(value: '12', child: Text('Grade 12')),
                          DropdownMenuItem(value: 'Grad', child: Text('Graduate')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGrade = value ?? '';
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _saveProfileInfo,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Profile Info'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Preferences
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Preferences',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      // Use a local SwitchTheme so inactive thumb color appears grey
                      Theme(
                        data: Theme.of(context).copyWith(
                          switchTheme: SwitchThemeData(
                            thumbColor: MaterialStateProperty.resolveWith(
                                (states) {
                              // Selected -> theme primary, otherwise a neutral grey
                              if (states.contains(MaterialState.selected)) {
                                return Theme.of(context).colorScheme.primary;
                              }
                              return const Color(0xFFBDBDBD); // grey[400]
                            }),
                            trackColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.selected)) {
                                return Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha((0.35 * 255).round());
                              }
                              return const Color(0xFF9E9E9E).withAlpha(80);
                            }),
                            // Remove the white overlay/outline when inactive by making overlay transparent
                            overlayColor: MaterialStateProperty.resolveWith((states) {
                              if (states.contains(MaterialState.selected)) {
                                return Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withAlpha((0.12 * 255).round());
                              }
                              return Colors.transparent;
                            }),
                            splashRadius: 0,
                          ),
                        ),
                        child: Consumer<AppSettingsProvider>(
                          builder: (context, appSettings, _) {
                            return Column(
                              children: [
                                SwitchListTile(
                                  title: const Text('Enable notifications'),
                                  value: _enableNotifications,
                                  onChanged: (v) => _setEnableNotifications(v),
                                ),
                                SwitchListTile(
                                  title: const Text('Show images in feed'),
                                  value: _showImagesInFeed,
                                  onChanged: (v) => _setShowImagesInFeed(v),
                                ),
                                const Divider(height: 24),
                                SwitchListTile(
                                  title: const Text('Auto-save posts when liked'),
                                  subtitle: const Text('Automatically bookmark posts you like'),
                                  value: appSettings.autoSaveOnLike,
                                  onChanged: (v) async {
                                    await appSettings.setAutoSaveOnLike(v);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(v ? 'Auto-save enabled' : 'Auto-save disabled'),
                                          backgroundColor: Colors.grey[800],
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                SwitchListTile(
                                  title: const Text('Like notifications'),
                                  subtitle: const Text('Get notified when someone likes your posts'),
                                  value: appSettings.likeNotifications,
                                  onChanged: (v) async {
                                    await appSettings.setLikeNotifications(v);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(v ? 'Like notifications enabled' : 'Like notifications disabled'),
                                          backgroundColor: Colors.grey[800],
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                SwitchListTile(
                                  title: const Text('Comment notifications'),
                                  subtitle: const Text('Get notified when someone comments on your posts'),
                                  value: appSettings.commentNotifications,
                                  onChanged: (v) async {
                                    await appSettings.setCommentNotifications(v);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(v ? 'Comment notifications enabled' : 'Comment notifications disabled'),
                                          backgroundColor: Colors.grey[800],
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                                SwitchListTile(
                                  title: const Text('Public profile'),
                                  subtitle: Text(appSettings.profileIsPublic 
                                    ? 'Your profile is visible to everyone' 
                                    : 'Your profile is private'),
                                  value: appSettings.profileIsPublic,
                                  onChanged: (v) async {
                                    await appSettings.setProfileVisibility(v);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(v ? 'Profile is now public' : 'Profile is now private'),
                                          backgroundColor: Colors.grey[800],
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      // Font Size Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Font Size',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          TextButton.icon(
                            onPressed: () {
                              final themeProvider = context.read<ThemeProvider>();
                              themeProvider.setFontSize(1.0);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Font size reset to 100%')),
                                );
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('Reset'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Row(
                            children: [
                              const Text('A', style: TextStyle(fontSize: 12)),
                              Expanded(
                                child: Slider(
                                  value: themeProvider.fontSize,
                                  min: 0.5,
                                  max: 2.0,
                                  onChanged: (value) {
                                    themeProvider.setFontSize(value);
                                  },
                                  onChangeEnd: (value) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Font size updated to ${(value * 100).round()}%')),
                                      );
                                    }
                                  },
                                ),
                              ),
                              const Text('A', style: TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text('${(themeProvider.fontSize * 100).round()}%',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Theme Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Theme',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              switchTheme: SwitchThemeData(
                                thumbColor: MaterialStateProperty.resolveWith(
                                    (states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Theme.of(context).colorScheme.primary;
                                  }
                                  return const Color(0xFFBDBDBD);
                                }),
                                trackColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha((0.35 * 255).round());
                                  }
                                  return const Color(0xFF9E9E9E).withAlpha(80);
                                }),
                                overlayColor: MaterialStateProperty.resolveWith((states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withAlpha((0.12 * 255).round());
                                  }
                                  return Colors.transparent;
                                }),
                                splashRadius: 0,
                              ),
                            ),
                            child: SwitchListTile(
                              title: const Text('Dark Mode'),
                              subtitle:
                                  Text(themeProvider.isDarkMode ? 'On' : 'Off'),
                              value: themeProvider.isDarkMode,
                              onChanged: (bool value) {
                                themeProvider.toggleTheme();
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return Row(
                            children: [
                              const Text('Theme color:'),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: themeProvider.selectedColorName,
                                  items: themeProvider.availableColors
                                      .map((name) => DropdownMenuItem(
                                          value: name, child: Text(name)))
                                      .toList(),
                                  onChanged: (s) {
                                    if (s != null) themeProvider.setColor(s);
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _resetTheme,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Theme to Default'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Connected Accounts Section (Mockup)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          const Text(
                            'Connected Accounts',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Link your social media accounts to share posts across platforms',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      _buildSocialAccountTile(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        color: const Color(0xFF1877F2),
                        isConnected: _facebookConnected,
                      ),
                      const Divider(height: 24),
                      _buildSocialAccountTile(
                        icon: Icons.close,
                        label: 'X (Twitter)',
                        color: Colors.black,
                        isConnected: _twitterConnected,
                      ),
                      const Divider(height: 24),
                      _buildSocialAccountTile(
                        icon: Icons.camera_alt,
                        label: 'Instagram',
                        color: const Color(0xFFE4405F),
                        isConnected: _instagramConnected,
                      ),
                      const Divider(height: 24),
                      _buildSocialAccountTile(
                        icon: Icons.work,
                        label: 'LinkedIn',
                        color: const Color(0xFF0A66C2),
                        isConnected: _linkedinConnected,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Account Actions
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => _showChangePasswordDialog(),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.school),
                      title: const Text('Show Tutorial Again'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        // Reset onboarding and show it
                        await OnboardingHelper.resetOnboarding();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tutorial will show on next app launch'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.logout,
                          color: Theme.of(context).colorScheme.error),
                      title: const Text('Logout'),
                      textColor: Theme.of(context).colorScheme.error,
                      onTap: () async {
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text('Are you sure you want to logout?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                  child: const Text('Logout'),
                                ),
                              ],
                            );
                          },
                        );

                        // Only logout if confirmed
                        if (confirmed == true) {
                          await authService.signOut();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Logged out successfully')));
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
        );
      },
    );
  }
  
  Widget _buildSocialAccountTile({
    required IconData icon,
    required String label,
    required Color color,
    required bool isConnected,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        isConnected ? 'Connected' : 'Not connected',
        style: TextStyle(
          fontSize: 13,
          color: isConnected ? Colors.green : Colors.grey,
        ),
      ),
      trailing: ElevatedButton(
        onPressed: () {
          if (isConnected) {
            _disconnectSocialMedia(label);
          } else {
            _showSocialMediaSignIn(label, color, icon);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isConnected ? Colors.grey[300] : color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          isConnected ? 'Disconnect' : 'Connect',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isConnected ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
  
  Future<void> _disconnectSocialMedia(String platform) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      if (platform == 'Facebook') {
        _facebookConnected = false;
        prefs.setBool('facebookConnected', false);
      } else if (platform == 'X (Twitter)') {
        _twitterConnected = false;
        prefs.setBool('twitterConnected', false);
      } else if (platform == 'Instagram') {
        _instagramConnected = false;
        prefs.setBool('instagramConnected', false);
      } else if (platform == 'LinkedIn') {
        _linkedinConnected = false;
        prefs.setBool('linkedinConnected', false);
      }
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.link_off, color: Colors.white),
              const SizedBox(width: 12),
              Text('$platform disconnected'),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  
  void _showSocialMediaSignIn(String platform, Color color, IconData icon) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String? errorMessage;
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Text('Sign in to $platform'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message banner
                  if (errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email or Username',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person),
                      hintText: 'Enter your $platform email',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (value) {
                      if (errorMessage != null) {
                        setDialogState(() => errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      hintText: 'Enter your password',
                    ),
                    obscureText: true,
                    onChanged: (value) {
                      if (errorMessage != null) {
                        setDialogState(() => errorMessage = null);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  // Privacy Notice (like our app)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'By connecting, you allow FBLA Connect to post on your behalf and access basic profile information.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  emailController.dispose();
                  passwordController.dispose();
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Validate fields
                  if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
                    setDialogState(() {
                      errorMessage = 'Please fill in all fields';
                    });
                    return;
                  }
                  
                  emailController.dispose();
                  passwordController.dispose();
                  Navigator.pop(dialogContext);
                  
                  // Save connection state
                  final prefs = await SharedPreferences.getInstance();
                  this.setState(() {
                    if (platform == 'Facebook') {
                      _facebookConnected = true;
                      prefs.setBool('facebookConnected', true);
                    } else if (platform == 'X (Twitter)') {
                      _twitterConnected = true;
                      prefs.setBool('twitterConnected', true);
                    } else if (platform == 'Instagram') {
                      _instagramConnected = true;
                      prefs.setBool('instagramConnected', true);
                    } else if (platform == 'LinkedIn') {
                      _linkedinConnected = true;
                      prefs.setBool('linkedinConnected', true);
                    }
                  });
                  
                  // Show success message
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.white),
                            const SizedBox(width: 12),
                            Text('$platform connected successfully!'),
                          ],
                        ),
                        backgroundColor: Colors.green[700],
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Connect'),
              ),
            ],
          );
        },
      ),
    );
  }
}
