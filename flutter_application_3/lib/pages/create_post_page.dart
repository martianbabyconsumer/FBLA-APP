import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/post_repository.dart';
import '../providers/user_provider.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              
              // Get the current user's display name from UserProvider
              final userProvider = context.read<UserProvider>();
              
              final newPost = Post(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                handle: '@you',
                displayName: userProvider.displayName,
                dateLabel: '${DateTime.now().month}/${DateTime.now().day}',
                title: _titleController.text.trim(),
                body: _bodyController.text.trim(),
                imageUrl: _imageController.text.trim().isEmpty ? null : _imageController.text.trim(),
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
            // Optional image URL
            TextField(
              controller: _imageController,
              decoration: const InputDecoration(
                hintText: 'Image URL (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            if (_imageController.text.trim().isNotEmpty)
              SizedBox(
                height: 160,
                child: Image.network(
                  _imageController.text.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Center(child: Text('Invalid image URL')),
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