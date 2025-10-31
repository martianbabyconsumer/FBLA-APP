import 'package:flutter/material.dart';
import '../models/chapter_message.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'calendar_page.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';

class ChapterPage extends StatefulWidget {
  const ChapterPage({super.key});

  @override
  State<ChapterPage> createState() => _ChapterPageState();
}

class _ChapterPageState extends State<ChapterPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<Channel> _channels;
  late Channel _selectedChannel;
  List<ChapterMessage> _messages = [];
  bool _showEmojiPicker = false;
  
  // Calendar state
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void initState() {
    super.initState();
    _initializeChannels();
    _loadMessages();
    _initializeCalendar();
  }

  void _initializeCalendar() {
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    // Events are now managed by CalendarProvider
  }

  void _initializeChannels() {
    _channels = [
      Channel(
        id: 'announcements',
        name: 'announcements',
        icon: Icons.campaign,
        isAnnouncement: true,
        description: 'Important chapter announcements',
        isLocked: true,
      ),
      Channel(
        id: 'general',
        name: 'general',
        icon: Icons.chat,
        description: 'General chapter discussion',
      ),
      Channel(
        id: 'events',
        name: 'events',
        icon: Icons.event,
        description: 'Upcoming events and activities',
      ),
      Channel(
        id: 'chapter-calendar',
        name: 'chapter-calendar',
        icon: Icons.calendar_month,
        description: 'Shared chapter calendar',
      ),
      Channel(
        id: 'competitions',
        name: 'competitions',
        icon: Icons.emoji_events,
        description: 'Competition preparation and discussions',
      ),
      Channel(
        id: 'resources',
        name: 'resources',
        icon: Icons.book,
        description: 'Study materials and resources',
      ),
    ];
    _selectedChannel = _channels[1]; // Start with general channel
  }

  void _loadMessages() {
    // In a real app, this would load messages from a backend
    final now = DateTime.now();
    _messages = [
      ChapterMessage(
        id: '1',
        authorId: 'advisor',
        authorName: 'Chapter Advisor',
        content: '🎉 Welcome to our FBLA Chapter! This is our new communication platform. Please read the rules and guidelines pinned in the announcements channel.',
        timestamp: now.subtract(const Duration(days: 1)),
        type: MessageType.announcement,
        isPinned: true,
      ),
      ChapterMessage(
        id: '2',
        authorId: 'president',
        authorName: 'Chapter President',
        content: 'Our next meeting will be on Friday at 3:30 PM in Room 201. We\'ll be discussing upcoming competition preparations!',
        timestamp: now.subtract(const Duration(hours: 2)),
        type: MessageType.eventNotification,
      ),
    ];
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChapterMessage(
          id: DateTime.now().toString(),
          authorId: 'currentUser',
          authorName: 'You',
          content: text,
          timestamp: DateTime.now(),
        ),
      );
    });

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleReaction(ChapterMessage message, String emoji) {
    setState(() {
      var reaction = message.reactions.firstWhere(
        (r) => r.emoji == emoji,
        orElse: () {
          final newReaction = ReactionCount(emoji: emoji, userIds: ['currentUser']);
          message.reactions.add(newReaction);
          return newReaction;
        },
      );

      if (reaction.userIds.contains('currentUser')) {
        reaction.userIds.remove('currentUser');
        if (reaction.userIds.isEmpty) {
          message.reactions.remove(reaction);
        }
      } else {
        reaction.userIds.add('currentUser');
      }
    });
  }

  // Calendar helper methods
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
      builder: (dialogContext) => StatefulBuilder(
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
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: _titleController.text.trim().isEmpty
                ? null
                : () => Navigator.pop(dialogContext, true),
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      final event = Event(
        title: _titleController.text,
        description: _descriptionController.text,
        startTime: _startTime,
        endTime: _endTime,
        color: Colors.blue,
      );

      // Use the provider from the widget's context, not the dialog context
      Provider.of<CalendarProvider>(context, listen: false).addChapterEvent(_selectedDay, event);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Row(
        children: [
          // Channel sidebar
          Container(
            width: 240,
            color: isDark ? Colors.grey[900] : Colors.grey[100],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.primaryColor,
                  child: Row(
                    children: [
                      const Icon(Icons.school, color: Colors.white),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'FBLA Chapter',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _channels.map((channel) {
                      final isSelected = channel == _selectedChannel;
                      return ListTile(
                        leading: Icon(
                          channel.icon,
                          color: isSelected
                              ? theme.primaryColor
                              : isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                        ),
                        title: Text(
                          '#${channel.name}',
                          style: TextStyle(
                            color: isSelected
                                ? theme.primaryColor
                                : isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedChannel = channel;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Messages area
          Expanded(
            child: Column(
              children: [
                // Channel header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedChannel.icon,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${_selectedChannel.name}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _selectedChannel.description,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Content area - show calendar for chapter-calendar channel, messages for others
                Expanded(
                  child: _selectedChannel.id == 'chapter-calendar'
                      ? _buildCalendarView(theme, isDark)
                      : _buildMessagesView(theme, isDark),
                ),
                // Message input
                if (!_selectedChannel.isLocked && _selectedChannel.id != 'chapter-calendar')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            // TODO: Implement file attachment
                          },
                          tooltip: 'Add attachment',
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText:
                                  'Message #${_selectedChannel.name}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            minLines: 1,
                            maxLines: 5,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions_outlined),
                          onPressed: () {
                            setState(() {
                              _showEmojiPicker = !_showEmojiPicker;
                            });
                          },
                          tooltip: 'Add emoji',
                        ),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                          tooltip: 'Send message',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView(ThemeData theme, bool isDark) {
    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, child) {
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
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
                      eventLoader: (day) => calendarProvider.getChapterEventsForDay(day),
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
                        setState(() {
                          _focusedDay = focusedDay;
                        });
                      },
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: theme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            'Events on ${DateFormat.yMMMd().format(_selectedDay)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            onPressed: _showAddEventDialog,
                            tooltip: 'Add Event',
                            color: theme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    ...calendarProvider.getChapterEventsForDay(_selectedDay).map((event) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
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
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              calendarProvider.removeChapterEvent(_selectedDay, event);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMessagesView(ThemeData theme, bool isDark) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showHeader = index == 0 ||
            message.authorId != _messages[index - 1].authorId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    backgroundColor: theme.primaryColor,
                    child: Text(
                      message.authorName[0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd()
                        .add_jm()
                        .format(message.timestamp),
                    style: TextStyle(
                      color: isDark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  if (message.isPinned) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.push_pin,
                      size: 16,
                      color: theme.primaryColor,
                    ),
                  ],
                ],
              ),
            ],
            Padding(
              padding: EdgeInsets.only(
                left: 48,
                top: showHeader ? 8 : 4,
                right: 16,
                bottom: 4,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message.content),
                  if (message.reactions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: message.reactions.map((reaction) {
                        final isReacted = reaction.userIds
                            .contains('currentUser');
                        return InkWell(
                          onTap: () => _toggleReaction(
                              message, reaction.emoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isReacted
                                  ? theme.primaryColor
                                      .withOpacity(0.1)
                                  : isDark
                                      ? Colors.grey[800]
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                              border: isReacted
                                  ? Border.all(
                                      color: theme.primaryColor,
                                    )
                                  : null,
                            ),
                            child: Text(
                              '${reaction.emoji} ${reaction.count}',
                              style: TextStyle(
                                color: isReacted
                                    ? theme.primaryColor
                                    : null,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}