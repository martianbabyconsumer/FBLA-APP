import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../models/event.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Consumer<CalendarProvider>(
        builder: (context, provider, _) {
          return _CalendarView(
            provider: provider,
            isPersonal: _tabController.index == 0,
            focusedDay: _focusedDay,
            selectedDay: _selectedDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) {
              setState(() {
                _focusedDay = focused;
              });
            },
          );
        },
      ),
      floatingActionButton: Consumer<CalendarProvider>(
        builder: (context, provider, _) {
          return FloatingActionButton.extended(
            onPressed: () => _showAddDialog(
              context,
              provider,
              _tabController.index == 0,
              _selectedDay,
            ),
            icon: const Icon(Icons.add),
            label: const Text('New Event'),
          );
        },
      ),
    );
  }

  static void _showAddDialog(
    BuildContext context,
    CalendarProvider provider,
    bool isPersonal,
    DateTime selectedDay,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (stateContext, setState) {
            final canAdd = titleController.text.trim().isNotEmpty;
            
            return AlertDialog(
              title: Text('Add ${isPersonal ? "Personal" : "Chapter"} Event'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter event title',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Enter description',
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
                                context: dialogContext,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() => startTime = time);
                              }
                            },
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              startTime?.format(dialogContext) ?? 'Start',
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay.now(),
                              );
                              if (time != null) {
                                setState(() => endTime = time);
                              }
                            },
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              endTime?.format(dialogContext) ?? 'End',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: canAdd
                      ? () {
                          final title = titleController.text.trim();
                          final desc = descController.text.trim();
                          
                          // Validate title length
                          if (title.length > 100) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Event title must be 100 characters or less'),
                                backgroundColor: Theme.of(context).colorScheme.error,
                              ),
                            );
                            return;
                          }
                          
                          // Validate that end time is after start time
                          if (startTime != null && endTime != null) {
                            final now = DateTime.now();
                            final startDateTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              startTime!.hour,
                              startTime!.minute,
                            );
                            final endDateTime = DateTime(
                              now.year,
                              now.month,
                              now.day,
                              endTime!.hour,
                              endTime!.minute,
                            );
                            
                            if (!endDateTime.isAfter(startDateTime)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('End time must be after start time'),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                ),
                              );
                              return;
                            }
                          }
                          
                          final event = Event(
                            title: title,
                            description: desc,
                            startTime: startTime,
                            endTime: endTime,
                            color: isPersonal ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.secondary,
                          );
                          if (isPersonal) {
                            provider.addPersonalEvent(selectedDay, event);
                          } else {
                            provider.addChapterEvent(selectedDay, event);
                          }
                          Navigator.pop(dialogContext);
                        }
                      : null,
                  child: const Text('ADD'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _CalendarView extends StatelessWidget {
  final CalendarProvider provider;
  final bool isPersonal;
  final DateTime focusedDay;
  final DateTime selectedDay;
  final Function(DateTime, DateTime) onDaySelected;
  final Function(DateTime) onPageChanged;

  const _CalendarView({
    required this.provider,
    required this.isPersonal,
    required this.focusedDay,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final events = isPersonal
        ? provider.getPersonalEventsForDay(selectedDay)
        : provider.getChapterEventsForDay(selectedDay);

    return Column(
      children: [
        TableCalendar<Event>(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2026, 12, 31),
          focusedDay: focusedDay,
          selectedDayPredicate: (day) => isSameDay(selectedDay, day),
          calendarFormat: CalendarFormat.month,
          availableCalendarFormats: const {CalendarFormat.month: 'Month'},
          eventLoader: (day) => isPersonal
              ? provider.getPersonalEventsForDay(day)
              : provider.getChapterEventsForDay(day),
          startingDayOfWeek: StartingDayOfWeek.sunday,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            leftChevronIcon: Icon(Icons.chevron_left, color: theme.primaryColor),
            rightChevronIcon: Icon(Icons.chevron_right, color: theme.primaryColor),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            weekendTextStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.grey[850],
            ),
            selectedDecoration: BoxDecoration(
              color: theme.primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: onDaySelected,
          onPageChanged: onPageChanged,
        ),
        const Divider(height: 1),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Text(
                    'No events for this day',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return Dismissible(
                      key: Key('$isPersonal-${event.title}-$index'),
                      background: Container(
                        color: Theme.of(context).colorScheme.error,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onError),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (_) {
                        if (isPersonal) {
                          provider.removePersonalEvent(selectedDay, event);
                        } else {
                          provider.removeChapterEvent(selectedDay, event);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Event deleted'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () {
                                if (isPersonal) {
                                  provider.addPersonalEvent(selectedDay, event);
                                } else {
                                  provider.addChapterEvent(selectedDay, event);
                                }
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
                            height: 50,
                            color: event.color,
                          ),
                          title: Text(
                            event.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.startTime != null &&
                                  event.endTime != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '${event.startTime!.format(context)} - ${event.endTime!.format(context)}',
                                  style: TextStyle(color: theme.primaryColor),
                                ),
                              ],
                              if (event.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(event.description),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
