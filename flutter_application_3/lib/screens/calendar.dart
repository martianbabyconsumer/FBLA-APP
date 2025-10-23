import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final List<Map<String, String>> _events = [];

  Future<void> _addEvent() async {
    String title = '';
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add event'),
        content: Form(
          key: formKey,
          child: TextFormField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Event title'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a title' : null,
            onSaved: (v) => title = v ?? '',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                formKey.currentState?.save();
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true) {
      final date = DateTime.now();
      setState(() {
        _events.add({'title': title, 'date': '${date.month}/${date.day}/${date.year}'});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: _events.isEmpty
          ? const Center(child: Text('No events yet'))
          : ListView.separated(
              itemCount: _events.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) => ListTile(
                title: Text(_events[i]['title']!),
                subtitle: Text(_events[i]['date']!),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
      ),
    );
  }
}
