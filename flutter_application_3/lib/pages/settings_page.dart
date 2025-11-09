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

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _displayNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _webImage; // For web platform
  bool _enableNotifications = false;
  bool _showImagesInFeed = true;

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
                      onTap: () {
                        // TODO: Implement password change flow (placeholder)
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Change password not implemented')));
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
}
