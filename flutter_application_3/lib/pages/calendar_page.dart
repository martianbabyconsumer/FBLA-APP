import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';


class Event {
  final String title;
  final String description;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final Color color;

  Event({
    required this.title,
    required this.description,
    this.startTime,
    this.endTime,
    this.color = Colors.blue,
  });
}

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    // Events are now managed by CalendarProvider
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        // Force a refresh of the selected day's events
        _onDaySelected(_selectedDay, _focusedDay);
      });
    }
  }

  List<Event> _getEventsForDay(DateTime day) {
    final provider = context.read<CalendarProvider>();
    // Normalize the date to midnight to ensure consistent lookup
    if (_tabController.index == 0) {
      return provider.getPersonalEventsForDay(day);
    } else {
      return provider.getChapterEventsForDay(day);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
  }

  Future<void> _showAddEventDialog() async {
    _titleController.clear();
    _descriptionController.clear();
    _startTime = null;
    _endTime = null;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Event'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'Enter event title',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter event description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => _startTime = time);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(_startTime != null
                            ? _startTime!.format(context)
                            : 'Start Time'),
                      ),
                    ),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            setDialogState(() => _endTime = time);
                          }
                        },
                        icon: const Icon(Icons.access_time),
                        label: Text(_endTime != null
                            ? _endTime!.format(context)
                            : 'End Time'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: _titleController.text.trim().isEmpty
                ? null  // Disable the button if title is empty
                : () => Navigator.pop(context, true),
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final event = Event(
        title: _titleController.text,
        description: _descriptionController.text,
        startTime: _startTime,
        endTime: _endTime,
        color: Colors.blue,
      );

      final provider = context.read<CalendarProvider>();
      if (_tabController.index == 0) {
        provider.addPersonalEvent(_selectedDay, event);
      } else {
        provider.addChapterEvent(_selectedDay, event);
      }
      setState(() {}); // Refresh the UI
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Personal'),
            Tab(icon: Icon(Icons.group), text: 'Chapter'),
          ],
        ),
      ),
      body: Column(
        children: [
          TableCalendar<Event>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2025, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: 'Month'
            },
            eventLoader: _getEventsForDay,
            startingDayOfWeek: StartingDayOfWeek.sunday,
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: theme.colorScheme.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: theme.colorScheme.primary,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[850],
              ),
              holidayTextStyle: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[850],
              ),
              selectedDecoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            onDaySelected: _onDaySelected,
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _getEventsForDay(_selectedDay).length,
              itemBuilder: (context, index) {
                final event = _getEventsForDay(_selectedDay)[index];
                return Dismissible(
                  key: ObjectKey(event),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    final provider = context.read<CalendarProvider>();
                    if (_tabController.index == 0) {
                      provider.removePersonalEvent(_selectedDay, event);
                    } else {
                      provider.removeChapterEvent(_selectedDay, event);
                    }
                    setState(() {}); // Refresh the UI
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Event deleted'),
                        action: SnackBarAction(
                          label: 'UNDO',
                          onPressed: () {
                            if (_tabController.index == 0) {
                              provider.addPersonalEvent(_selectedDay, event);
                            } else {
                              provider.addChapterEvent(_selectedDay, event);
                            }
                            setState(() {}); // Refresh the UI
                          },
                        ),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 12,
                        height: double.infinity,
                        color: event.color,
                      ),
                      title: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (event.startTime != null && event.endTime != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '${event.startTime!.format(context)} - ${event.endTime!.format(context)}',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(event.description),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 140,
        child: FloatingActionButton.extended(
          onPressed: _showAddEventDialog,
          icon: const Icon(Icons.add),
          label: const Text('New Event'),
        ),
      ),
    );
  }
}