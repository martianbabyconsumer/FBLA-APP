import 'package:flutter/material.dart';
import 'dart:io';

import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
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
  final _imageController = TextEditingController();
  XFile? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: () {
              if (!mounted) return;
              if (_titleController.text.trim().isEmpty ||
                  _bodyController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
                return;
              }

              // Get the current user's display name and userId from providers
              final userProvider = context.read<UserProvider>();
              final authService = context.read<AuthService>();

              final newPost = Post(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                handle: '@you',
                displayName: userProvider.displayName,
                dateLabel: '${DateTime.now().month}/${DateTime.now().day}',
                title: _titleController.text.trim(),
                body: _bodyController.text.trim(),
                userId: authService.user?.uid, // Store Firebase user ID
                // Prefer picked image path if available, otherwise use typed URL
                imageUrl: _pickedImage != null
                    ? _pickedImage!.path
                    : (_imageController.text.trim().isEmpty
                        ? null
                        : _imageController.text.trim()),
                comments: [],
              );

              if (mounted) {
                Navigator.of(context).pop(newPost);
              }
            },
            child: const Text('Post', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: 'Title',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            // Image input: either type a URL or pick from device
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _imageController,
                    decoration: InputDecoration(
                      hintText: 'Image URL (optional)',
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.link, color: theme.colorScheme.primary),
                    ),
                    keyboardType: TextInputType.url,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () async {
                    final picked = await _picker.pickImage(
                        source: ImageSource.gallery, maxWidth: 1600);
                    if (picked != null) {
                      setState(() {
                        _pickedImage = picked;
                        // clear typed URL if user picked an image
                        _imageController.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Pick'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_pickedImage != null)
              SizedBox(
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(_pickedImage!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (c, e, s) =>
                        const Center(child: Text('Invalid image')),
                  ),
                ),
              )
            else if (_imageController.text.trim().isNotEmpty)
              SizedBox(
                height: 160,
                child: Image.network(
                  _imageController.text.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) =>
                      const Center(child: Text('Invalid image URL')),
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  hintText: 'What do you want to share?',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
