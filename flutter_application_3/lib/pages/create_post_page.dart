import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repository/post_repository.dart';
import '../providers/user_provider.dart';
import '../providers/auth_service.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _customTagController = TextEditingController();
  
  // Available tags
  final List<String> _availableTags = [
    'Chapter News',
    'Chapter Events',
    'Meetings',
    'Fundraising',
    'Competition',
    'Community Service',
    'Leadership',
    'Business Tips',
    'Networking',
    'Career Advice',
    'Success Stories',
    'Questions',
    'Help Needed',
    'Announcements',
  ];
  
  final Set<String> _selectedTags = {};
  
  // Cross-platform posting state
  final Set<String> _selectedPlatforms = {};
  
  // Connected accounts state
  bool _facebookConnected = false;
  bool _twitterConnected = false;
  bool _instagramConnected = false;
  bool _linkedinConnected = false;

  @override
  void initState() {
    super.initState();
    _loadConnectedAccounts();
  }

  Future<void> _loadConnectedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _facebookConnected = prefs.getBool('facebookConnected') ?? false;
      _twitterConnected = prefs.getBool('twitterConnected') ?? false;
      _instagramConnected = prefs.getBool('instagramConnected') ?? false;
      _linkedinConnected = prefs.getBool('linkedinConnected') ?? false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _customTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post', style: TextStyle(color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                if (!mounted) return;
                if (_titleController.text.trim().isEmpty ||
                    _bodyController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in all fields')),
                  );
                  return;
                }

                // Get the current user's display name from UserProvider
                final userProvider = context.read<UserProvider>();
                final authService = context.read<AuthService>();

                final handleName = (userProvider.username != null && userProvider.username!.isNotEmpty) ? '@${userProvider.username}' : '@you';
                final newPost = Post(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  handle: handleName,
                  displayName: userProvider.displayName,
                  dateLabel: '${DateTime.now().month}/${DateTime.now().day}',
                  title: _titleController.text.trim(),
                  body: _bodyController.text.trim(),
                  imageUrl: null, // No image support
                  userId: authService.user?.uid, // Add user ID to track post ownership
                  profileImagePath: userProvider.profileImagePath, // Store user's profile picture
                  comments: [],
                  tags: _selectedTags.toList(), // Add selected tags
                  crossPostedTo: _selectedPlatforms.toList(), // Add cross-posted platforms
                );

                if (mounted) {
                  Navigator.of(context).pop(newPost);
                  
                  // Show success with cross-platform info
                  if (_selectedPlatforms.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                const SizedBox(width: 12),
                                const Text('Post created successfully!'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sharing to: ${_selectedPlatforms.join(', ')}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.green[700],
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: Text('Create Post', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Section with Icon
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha((0.3 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withAlpha((0.2 * 255).round())),
                ),
                child: TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Post Title',
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
                  ),
                  maxLines: 1,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 20),
              
              // Body Section with Icon
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha((0.5 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withAlpha((0.2 * 255).round())),
                ),
                child: TextField(
                  controller: _bodyController,
                  decoration: InputDecoration(
                    hintText: 'Share your thoughts, ideas, or updates...',
                    hintStyle: TextStyle(color: theme.hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: null,
                  textAlignVertical: TextAlignVertical.top,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              // Tags section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primary.withAlpha((0.2 * 255).round())),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withAlpha((0.1 * 255).round()),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.label, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Tags (${_selectedTags.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          _showAddCustomTagDialog();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Custom'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTags.add(tag);
                            } else {
                              _selectedTags.remove(tag);
                            }
                          });
                        },
                        backgroundColor: theme.cardColor,
                        selectedColor: theme.colorScheme.primaryContainer,
                        checkmarkColor: theme.colorScheme.onPrimaryContainer,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  if (_selectedTags.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedTags.map((tag) {
                        return Chip(
                          label: Text('#$tag'),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedTags.remove(tag);
                            });
                          },
                          backgroundColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Social Media Cross-Post Section (with connected account check)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary.withAlpha((0.2 * 255).round())),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withAlpha((0.1 * 255).round()),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.share, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Cross-Post to Social Media (${_selectedPlatforms.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select connected accounts to share your post',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildPlatformChip(
                        icon: Icons.facebook,
                        label: 'Facebook',
                        color: const Color(0xFF1877F2),
                        isConnected: _facebookConnected,
                      ),
                      _buildPlatformChip(
                        icon: Icons.close,
                        label: 'X',
                        color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                        isConnected: _twitterConnected,
                      ),
                      _buildPlatformChip(
                        icon: Icons.camera_alt,
                        label: 'Instagram',
                        color: const Color(0xFFE4405F),
                        isConnected: _instagramConnected,
                      ),
                      _buildPlatformChip(
                        icon: Icons.work,
                        label: 'LinkedIn',
                        color: const Color(0xFF0A66C2),
                        isConnected: _linkedinConnected,
                      ),
                    ],
                  ),
                  if (_selectedPlatforms.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedPlatforms.map((platform) {
                        return Chip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getPlatformIcon(platform), size: 14, color: theme.colorScheme.onPrimaryContainer),
                              const SizedBox(width: 4),
                              Text(platform),
                            ],
                          ),
                          deleteIcon: Icon(Icons.close, size: 18, color: theme.colorScheme.onPrimaryContainer),
                          onDeleted: () {
                            setState(() {
                              _selectedPlatforms.remove(platform);
                            });
                          },
                          backgroundColor: theme.colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPlatformChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isConnected,
  }) {
    final isSelected = _selectedPlatforms.contains(label);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon, 
            size: 16, 
            color: isConnected 
                ? color 
                : theme.colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(width: 6),
          Text(label),
          if (!isConnected) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.lock, 
              size: 12, 
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ],
      ),
      selected: isSelected,
      onSelected: isConnected ? (selected) {
        setState(() {
          if (selected) {
            _selectedPlatforms.add(label);
          } else {
            _selectedPlatforms.remove(label);
          }
        });
      } : null,
      backgroundColor: isConnected 
          ? theme.cardColor 
          : (isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)),
      selectedColor: color.withOpacity(isDark ? 0.3 : 0.2),
      checkmarkColor: color,
      disabledColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
      labelStyle: TextStyle(
        color: isConnected 
            ? (isSelected ? color : theme.colorScheme.onSurface)
            : theme.colorScheme.onSurface.withOpacity(0.4),
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected 
            ? color 
            : (isConnected 
                ? theme.colorScheme.outline.withOpacity(0.5)
                : theme.colorScheme.outline.withOpacity(0.3)),
        width: isSelected ? 2 : 1,
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Facebook': return Icons.facebook;
      case 'X': return Icons.close;
      case 'Instagram': return Icons.camera_alt;
      case 'LinkedIn': return Icons.work;
      default: return Icons.share;
    }
  }

  void _showAddCustomTagDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Tag'),
        content: TextField(
          controller: _customTagController,
          decoration: const InputDecoration(
            hintText: 'Enter tag name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _customTagController.clear();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final customTag = _customTagController.text.trim();
              if (customTag.isNotEmpty) {
                setState(() {
                  _selectedTags.add(customTag);
                });
                Navigator.pop(context);
                _customTagController.clear();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}