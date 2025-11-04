import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final List<_Note> _notes = [];

  @override
  void dispose() {
    super.dispose();
  }

  void _addExample() {
    final svc = context.read<NotificationService>();
    final delay = const Duration(seconds: 3);
    final id = svc.scheduleNotification(
      title: 'Example Notification',
      body: 'This is an example notification scheduled after 3s.',
      delay: delay,
    );
    setState(() {
      _notes.add(_Note(
          id: id,
          title: 'Example Notification',
          body: 'This is an example notification scheduled after 3s.',
          scheduledAt: DateTime.now().add(delay)));
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Example notification scheduled (3s)')));
    }
  }

  void _cancel(String id) {
    final svc = context.read<NotificationService>();
    svc.cancelNotification(id);
    setState(() {
      _notes.removeWhere((n) => n.id == id);
    });
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Notification cancelled')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _addExample,
                  icon: const Icon(Icons.add_alert),
                  label: const Text('Add example notification'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Scheduled notifications will appear as SnackBars when the time arrives.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _notes.isEmpty
                  ? Center(
                      child: Text('No scheduled notifications',
                          style: Theme.of(context).textTheme.bodyMedium),
                    )
                  : ListView.builder(
                      itemCount: _notes.length,
                      itemBuilder: (context, i) {
                        final n = _notes[i];
                        return Card(
                          child: ListTile(
                            title: Text(n.title),
                            subtitle: Text(
                                '${n.body}\nScheduled: ${n.scheduledAt.toLocal().toString().split('.').first}'),
                            isThreeLine: true,
                            trailing: IconButton(
                              icon: const Icon(Icons.cancel),
                              onPressed: () => _cancel(n.id),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Note {
  final String id;
  final String title;
  final String body;
  final DateTime scheduledAt;

  _Note({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledAt,
  });
}
