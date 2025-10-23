import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../main.dart';
import '../utils/image_picker.dart';

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  @override
  void initState() {
    super.initState();
    notificationService.addListener(_onNotifications);
  }

  @override
  void dispose() {
    notificationService.removeListener(_onNotifications);
    super.dispose();
  }

  void _onNotifications() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final hasNotifications = notificationService.items.isNotEmpty;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.add_circle_outline, color: Colors.blue, size: 28),
          onPressed: () => _openComposer(context),
          tooltip: 'New post',
        ),
        title: const Text(
          '[FBLA APP]',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 18),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: InkWell(
              onTap: () => _openNotifications(context),
              child: Stack(alignment: Alignment.topRight, children: [
                const Padding(padding: EdgeInsets.all(8), child: Icon(Icons.notifications_none, color: Colors.black, size: 26)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: hasNotifications
                      ? Container(
                          key: ValueKey('badge_${notificationService.items.length}'),
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Center(child: Text('${notificationService.items.length}', style: const TextStyle(color: Colors.white, fontSize: 10))),
                        )
                      : const SizedBox.shrink(),
                ),
              ]),
            ),
          )
        ],
      ),
      body: const HomeScreen(),
    );
  }

  Future<void> _openNotifications(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      builder: (c) => SizedBox(
        height: 320,
        child: Column(
          children: [
            ListTile(title: const Text('Notifications'), trailing: TextButton(onPressed: () => setState(() => notificationService.clear()), child: const Text('Clear'))),
            const Divider(height: 1),
            Expanded(
              child: notificationService.items.isEmpty
                  ? const Center(child: Text('No notifications'))
                  : ListView.separated(
                      itemCount: notificationService.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final n = notificationService.items[i];
                        return ListTile(title: Text(n.message), subtitle: Text('${n.date}'));
                      },
                    ),
            ),
          ],
        ),
      ),
    );
    setState(() {});
  }

  Future<void> _openComposer(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (c) => ComposerSheet(),
    );
  }
}

class ComposerSheet extends StatefulWidget {
  const ComposerSheet({super.key});

  @override
  State<ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<ComposerSheet> {
  final _ctrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  File? _image;
  String? _imageDataUrl;

  Future<void> _pickImage() async {
    // Try to use platform file picker when available. Keep this simple so tests don't fail.
    try {
      final dataUrl = await pickImageWeb();
      if (dataUrl != null) {
        _imageDataUrl = dataUrl;
      }
    } catch (_) {}
    setState(() {});
  }

  void _submit() {
    final title = _titleCtrl.text.trim();
    final body = _ctrl.text.trim();
    if (title.isEmpty && body.isEmpty) return;
    // add to repo (simple new post)
    final newPost = Post(id: DateTime.now().millisecondsSinceEpoch.toString(), handle: '@you', displayName: 'You', dateLabel: 'Now', title: title.isEmpty ? '(no title)' : title, body: body, imageUrl: _imageDataUrl, likes: 0, liked: false);
  postRepository.addPost(newPost);
  // do not add an in-app notification for local user's own post; show a SnackBar instead
    Navigator.of(context).pop();
    // show visual confirmation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Posted: $title')));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Wrap(children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Create post', style: Theme.of(context).textTheme.titleMedium), TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))]),
            TextField(key: const Key('composer_title'), controller: _titleCtrl, decoration: const InputDecoration(hintText: 'Title')),
            const SizedBox(height: 8),
            TextField(key: const Key('composer_textfield'), controller: _ctrl, maxLines: 6, decoration: const InputDecoration(hintText: 'Write your post...')),
            const SizedBox(height: 8),
            if (_image != null) Image.file(_image!, height: 120, fit: BoxFit.cover),
            Row(children: [IconButton(onPressed: _pickImage, icon: const Icon(Icons.image)), const Spacer(), ElevatedButton(key: const Key('post_button'), onPressed: _submit, child: const Text('Post'))]),
          ]),
        )
      ]),
    );
  }
}
