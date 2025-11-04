import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _webImage; // For web platform
  bool _enableNotifications = false;
  bool _showImagesInFeed = true;

  @override
  void initState() {
    super.initState();
    // Load saved values from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      _displayNameController.text = userProvider.displayName;
      _usernameController.text = userProvider.username ?? '';
      _emailController.text = userProvider.email;

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
    _emailController.dispose();
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

        if (kIsWeb) {
          // For web, store the XFile and save its path to provider
          setState(() {
            _webImage = image;
          });
          await userProvider.updateProfileImage(image.path);
        } else {
          // For mobile, store the path directly
          await userProvider.updateProfileImage(image.path);
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

  Future<void> _saveSettings() async {
    final userProvider = context.read<UserProvider>();

    try {
      // Save both values at once
      await userProvider.saveSettings(
        _displayNameController.text,
        _emailController.text,
        username: _usernameController.text.trim().isEmpty ? null : _usernameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } on FormatException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _clearProfileImage() async {
    final userProvider = context.read<UserProvider>();
    await userProvider.updateProfileImage(null);
    setState(() {
      _webImage = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture cleared')));
    }
  }

  Future<void> _resetToDefaults() async {
    final userProvider = context.read<UserProvider>();
    final themeProvider = context.read<ThemeProvider>();
    try {
      await userProvider.updateDisplayName('John Doe');
      await userProvider.updateEmail('john.doe@example.com');
      await userProvider.updateProfileImage(null);
      // Reset theme color and ensure light mode
      await themeProvider.setColor('Blue');
      if (themeProvider.isDarkMode) await themeProvider.toggleTheme();
      // Reset local prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('enableNotifications');
      await prefs.remove('showImagesInFeed');
      await _loadLocalSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings reset to defaults')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to reset: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Intentionally remove the visible title per user request
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, _) {
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
                                Text(userProvider.displayName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(userProvider.email,
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
                      // Display name and email fields
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
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                        keyboardType: TextInputType.emailAddress,
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
                              onPressed: _resetToDefaults,
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
                        child: Column(
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
                          ],
                        ),
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
                      onTap: () {
                        // Implement logout: clear user data and navigate back to a login flow if present
                        userProvider.updateProfileImage(null);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Logged out (local state only)')));
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
