import 'package:flutter/material.dart';

class ChapterPage extends StatelessWidget {
  const ChapterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chapter'),
      ),
      body: const Center(
        child: Text('Chapter Page'),
      ),
    );
  }
}