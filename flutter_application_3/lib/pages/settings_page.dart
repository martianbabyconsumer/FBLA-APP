import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
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
  final ImagePicker _picker = ImagePicker();
  XFile? _webImage; // For web platform

  @override
  void initState() {
    super.initState();
    // Load saved values from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      _displayNameController.text = userProvider.displayName;
      _emailController.text = userProvider.email;
      
      // For web, load the saved profile image path as _webImage if it exists
      if (kIsWeb && userProvider.profileImagePath != null) {
        setState(() {
          _webImage = XFile(userProvider.profileImagePath!);
        });
      }
    });
  }

  @override
  void dispose() {
    _displayNameController.dispose();
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

  Widget _buildProfileImage(UserProvider userProvider) {
    // For web, show the picked image or FBLA logo
    if (kIsWeb) {
      if (_webImage != null) {
        return Image.network(
          _webImage!.path,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
              Center(
                child: Stack(
                  children: [
                    ClipOval(
                      child: _buildProfileImage(userProvider),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                        child: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor,
                        radius: 18,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 18),
                          color: Theme.of(context).colorScheme.onPrimary,
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Display Name Field
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),

              // Email Field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // Theme Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Consumer<ThemeProvider>(
                        builder: (context, themeProvider, child) {
                          return SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: Text(themeProvider.isDarkMode ? 'On' : 'Off'),
                            value: themeProvider.isDarkMode,
                            onChanged: (bool value) {
                              themeProvider.toggleTheme();
                            },
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
                                  value: themeProvider.selectedColorName,
                                  items: themeProvider.availableColors.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
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

              const SizedBox(height: 24),
              
              // Account Actions
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: const Text('Change Password'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Implement password change
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                      title: const Text('Logout'),
                      textColor: Theme.of(context).colorScheme.error,
                      onTap: () {
                        // TODO: Implement logout
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