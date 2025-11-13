import 'package:flutter/material.dart';
import '../models/chapter_message.dart';
import '../models/event.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_service.dart';
import '../providers/user_provider.dart';
import '../repository/post_repository.dart';
import '../widgets/post_card.dart';
import '../pages/post_detail_page.dart';
import '../pages/create_post_page.dart';
import '../pages/member_profile_page.dart';
import '../utils/page_transitions.dart';

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

  // Calendar state
  late DateTime _focusedDay;
  late DateTime _selectedDay;

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
      Channel(
        id: 'chapter-posts',
        name: 'chapter-posts',
        icon: Icons.article,
        description: 'Chapter announcements and discussions',
      ),
    ];
    _selectedChannel = _channels[1]; // Start with general channel
  }

  void _loadMessages() {
    // Load messages based on selected channel
    final now = DateTime.now();
    
    // Different messages for each channel
    switch (_selectedChannel.id) {
      case 'announcements':
        _messages = [
          ChapterMessage(
            id: '1',
            authorId: 'advisor',
            authorName: 'Chapter Advisor',
            content: '🎉 Welcome to our FBLA Chapter! This is our communication hub for all chapter activities.',
            timestamp: now.subtract(const Duration(days: 3)),
            type: MessageType.announcement,
            isPinned: true,
          ),
          ChapterMessage(
            id: '2',
            authorId: 'advisor',
            authorName: 'Chapter Advisor',
            content: '📢 IMPORTANT: Nationals registration deadline is December 15th. Please see me if you plan to compete!',
            timestamp: now.subtract(const Duration(days: 2)),
            type: MessageType.announcement,
            isPinned: true,
          ),
          ChapterMessage(
            id: '3',
            authorId: 'president',
            authorName: 'Sarah Johnson',
            content: 'Chapter dues are due by November 30th. \$25 for the year. See treasurer for payment.',
            timestamp: now.subtract(const Duration(days: 1)),
            type: MessageType.announcement,
          ),
        ];
        break;
        
      case 'general':
        _messages = [
          ChapterMessage(
            id: '1',
            authorId: 'president',
            authorName: 'Sarah Johnson',
            content: 'Hey everyone! Great meeting today. Can\'t wait to see you all at the next one! 🎉',
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
          ChapterMessage(
            id: '2',
            authorId: 'member1',
            authorName: 'Alex Chen',
            content: 'Does anyone have notes from the last meeting? I had to leave early.',
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
          ChapterMessage(
            id: '3',
            authorId: 'member2',
            authorName: 'Marcus Davis',
            content: 'I can send them to you! DM me.',
            timestamp: now.subtract(const Duration(hours: 4)),
          ),
          ChapterMessage(
            id: '4',
            authorId: 'member3',
            authorName: 'Emily Rodriguez',
            content: 'Who\'s going to the regional conference next month? 🙋‍♀️',
            timestamp: now.subtract(const Duration(hours: 2)),
          ),
          ChapterMessage(
            id: '5',
            authorId: 'vp',
            authorName: 'Jordan Miller',
            content: 'I am! Can\'t wait, it\'s going to be awesome!',
            timestamp: now.subtract(const Duration(hours: 1)),
          ),
        ];
        break;
        
      case 'events':
        _messages = [
          ChapterMessage(
            id: '1',
            authorId: 'vp',
            authorName: 'Jordan Miller',
            content: '📅 Next chapter meeting: Friday, November 15th at 3:30 PM in Room 204',
            timestamp: now.subtract(const Duration(days: 2)),
            type: MessageType.eventNotification,
            isPinned: true,
          ),
          ChapterMessage(
            id: '2',
            authorId: 'treasurer',
            authorName: 'Ryan Thompson',
            content: '🎪 Fundraiser Car Wash this Saturday 9 AM - 2 PM at the school parking lot. All members please try to help out!',
            timestamp: now.subtract(const Duration(days: 1)),
            type: MessageType.eventNotification,
          ),
          ChapterMessage(
            id: '3',
            authorId: 'president',
            authorName: 'Sarah Johnson',
            content: 'Regional Leadership Conference is December 8-10 in Orlando. Sign-up sheet in room 201!',
            timestamp: now.subtract(const Duration(hours: 12)),
          ),
          ChapterMessage(
            id: '4',
            authorId: 'member1',
            authorName: 'Alex Chen',
            content: 'Don\'t forget about the community service event at the food bank this weekend! We need volunteers.',
            timestamp: now.subtract(const Duration(hours: 6)),
          ),
        ];
        break;
        
      case 'competitions':
        _messages = [
          ChapterMessage(
            id: '1',
            authorId: 'advisor',
            authorName: 'Chapter Advisor',
            content: '🏆 Competition categories for Nationals are now available. Check the FBLA website and let me know which events interest you!',
            timestamp: now.subtract(const Duration(days: 3)),
            isPinned: true,
          ),
          ChapterMessage(
            id: '2',
            authorId: 'member2',
            authorName: 'Marcus Davis',
            content: 'I\'m thinking about doing Business Financial Plan. Anyone want to team up?',
            timestamp: now.subtract(const Duration(days: 1)),
          ),
          ChapterMessage(
            id: '3',
            authorId: 'member3',
            authorName: 'Emily Rodriguez',
            content: 'I\'ll partner with you! We should start planning soon.',
            timestamp: now.subtract(const Duration(hours: 20)),
          ),
          ChapterMessage(
            id: '4',
            authorId: 'president',
            authorName: 'Sarah Johnson',
            content: 'Practice sessions will be held every Wednesday after school. Show up to work on your presentations!',
            timestamp: now.subtract(const Duration(hours: 10)),
          ),
          ChapterMessage(
            id: '5',
            authorId: 'vp',
            authorName: 'Jordan Miller',
            content: 'For those doing testing events, I have study guides from last year. Come see me.',
            timestamp: now.subtract(const Duration(hours: 5)),
          ),
        ];
        break;
        
      case 'resources':
        _messages = [
          ChapterMessage(
            id: '1',
            authorId: 'advisor',
            authorName: 'Chapter Advisor',
            content: '📚 STUDY RESOURCES\n\n🔗 FBLA Competitive Events: https://www.fbla.org/compete\n🔗 Practice Tests: https://www.fbla.org/test-prep\n🔗 Business Plan Templates: https://www.fbla.org/business-plan',
            timestamp: now.subtract(const Duration(days: 7)),
            isPinned: true,
          ),
          ChapterMessage(
            id: '2',
            authorId: 'advisor',
            authorName: 'Chapter Advisor',
            content: '💡 HELPFUL TIPS\n\n• Start preparing early for competitions\n• Practice your presentations in front of others\n• Review past test questions\n• Network with other chapter members',
            timestamp: now.subtract(const Duration(days: 6)),
            isPinned: true,
          ),
          ChapterMessage(
            id: '3',
            authorId: 'member2',
            authorName: 'Marcus Davis',
            content: 'I found this great YouTube channel for business concepts: "Business Basics Explained" - really helpful for Economics test prep!',
            timestamp: now.subtract(const Duration(days: 2)),
          ),
          ChapterMessage(
            id: '4',
            authorId: 'vp',
            authorName: 'Jordan Miller',
            content: 'Quizlet has tons of FBLA flashcard sets. Search "FBLA [your event name]" and you\'ll find study sets.',
            timestamp: now.subtract(const Duration(hours: 36)),
          ),
          ChapterMessage(
            id: '5',
            authorId: 'member3',
            authorName: 'Emily Rodriguez',
            content: '📖 Recommended Books:\n• "The Lean Startup" by Eric Ries\n• "How to Win Friends and Influence People" by Dale Carnegie\n• "Think and Grow Rich" by Napoleon Hill',
            timestamp: now.subtract(const Duration(hours: 12)),
          ),
        ];
        break;
        
      default:
        _messages = [];
    }
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
          final newReaction =
              ReactionCount(emoji: emoji, userIds: ['currentUser']);
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
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final titleController = TextEditingController();
    final descController = TextEditingController();
    TimeOfDay? startTime;
    TimeOfDay? endTime;

    await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (stateContext, setState) {
          final canAdd = titleController.text.trim().isNotEmpty;

          return AlertDialog(
            title: const Text('Add Chapter Event'),
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
                              context: dialogContext,
                              initialTime: TimeOfDay.now(),
                            );
                            if (time != null) {
                              setState(() => startTime = time);
                            }
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(
                              startTime?.format(dialogContext) ?? 'Start Time'),
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
                              endTime?.format(dialogContext) ?? 'End Time'),
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
                onPressed: canAdd
                    ? () {
                        final title = titleController.text.trim();
                        final desc = descController.text.trim();

                        // Validate title length
                        if (title.length > 100) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'Event title must be 100 characters or less'),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
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
                                content: const Text(
                                    'End time must be after start time'),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
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
                          color: Colors.orange,
                        );
                        provider.addChapterEvent(_selectedDay, event);
                        Navigator.pop(dialogContext, true);
                      }
                    : null,
                child: const Text('ADD'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Row(
        children: [
          // Channel sidebar
          Container(
            width: 240,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.primaryColor,
                  child: Row(
                    children: [
                      Icon(Icons.school, color: theme.colorScheme.onPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'FBLA Chapter',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
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
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.brightness == Brightness.dark
                                  ? theme.colorScheme.primary.withAlpha((0.25 * 255).round())
                                  : theme.colorScheme.primary.withAlpha((0.1 * 255).round())
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Icon(
                            channel.icon,
                            color: isSelected
                                ? theme.brightness == Brightness.dark
                                    ? theme.colorScheme.primary.withAlpha((0.9 * 255).round())
                                    : theme.primaryColor
                                : theme.unselectedWidgetColor,
                          ),
                          title: Text(
                            '#${channel.name}',
                            style: TextStyle(
                              color: isSelected
                                  ? theme.brightness == Brightness.dark
                                      ? theme.colorScheme.onSurface
                                      : theme.primaryColor
                                  : theme.colorScheme.onSurface
                                      .withAlpha((0.8 * 255).round()),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedChannel = channel;
                              _loadMessages(); // Reload messages for the selected channel
                            });
                          },
                        ),
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
                    border: Border.all(
                      color: theme.brightness == Brightness.light
                          ? theme.colorScheme.primary
                          : theme.dividerColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            theme.shadowColor.withAlpha((0.08 * 255).round()),
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
                          color: theme.colorScheme.onSurface
                              .withAlpha((0.65 * 255).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content area - show calendar, posts, resources, or messages based on channel
                Expanded(
                  child: _selectedChannel.id == 'chapter-calendar'
                      ? _buildCalendarView(theme)
                      : _selectedChannel.id == 'chapter-posts'
                        ? _buildPostsFeedView(theme)
                        : _selectedChannel.id == 'resources'
                          ? _buildResourcesView(theme)
                          : _buildMessagesView(theme),
                ),
                // Message input
                if (!_selectedChannel.isLocked &&
                    _selectedChannel.id != 'chapter-calendar' &&
                    _selectedChannel.id != 'resources')
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      border: Border.all(
                        color: theme.brightness == Brightness.light
                            ? theme.colorScheme.primary
                            : theme.dividerColor,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              theme.shadowColor.withAlpha((0.08 * 255).round()),
                          blurRadius: 4,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: InputDecoration(
                              hintText: 'Message #${_selectedChannel.name}',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.cardColor,
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
                        const SizedBox(width: 8),
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

  Widget _buildCalendarView(ThemeData theme) {
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
                      selectedDayPredicate: (day) =>
                          isSameDay(_selectedDay, day),
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {
                        CalendarFormat.month: 'Month'
                      },
                      eventLoader: (day) =>
                          calendarProvider.getChapterEventsForDay(day),
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      daysOfWeekHeight: 40,
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                        weekendStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
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
                          color: theme.colorScheme.onSurface,
                        ),
                        holidayTextStyle: TextStyle(
                          color: theme.colorScheme.onSurface,
                        ),
                        selectedDecoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: theme.colorScheme.primary
                              .withAlpha((0.3 * 255).round()),
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
                    ...calendarProvider
                        .getChapterEventsForDay(_selectedDay)
                        .map((event) {
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
                              if (event.startTime != null &&
                                  event.endTime != null) ...[
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
                            icon: Icon(Icons.delete,
                                color: theme.colorScheme.error),
                            onPressed: () {
                              calendarProvider.removeChapterEvent(
                                  _selectedDay, event);
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

  Widget _buildMessagesView(ThemeData theme) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final showHeader =
            index == 0 || message.authorId != _messages[index - 1].authorId;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      final authService = context.read<AuthService>();
                      final isOwnMessage = message.authorId == authService.user?.uid;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemberProfilePage(
                            userId: message.authorId,
                            isOwnProfile: isOwnMessage,
                          ),
                        ),
                      );
                    },
                    child: CircleAvatar(
                      backgroundColor: theme.primaryColor,
                      child: Text(
                        message.authorName[0],
                        style: TextStyle(color: theme.colorScheme.onPrimary),
                      ),
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
                    DateFormat.yMMMd().add_jm().format(message.timestamp),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface
                          .withAlpha((0.65 * 255).round()),
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
                        final isReacted =
                            reaction.userIds.contains('currentUser');
                        return InkWell(
                          onTap: () => _toggleReaction(message, reaction.emoji),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isReacted
                                  ? theme.primaryColor
                                      .withAlpha((0.1 * 255).round())
                                  : theme.cardColor,
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
                                color: isReacted ? theme.primaryColor : null,
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

  Widget _buildPostsFeedView(ThemeData theme) {
    return Consumer3<PostRepository, AppSettingsProvider, AuthService>(
      builder: (context, repo, settings, authService, _) {
        // Get chapter-related posts (posts with chapter-related tags)
        final chapterTags = ['Chapter News', 'Chapter Events', 'Meetings', 'Fundraising'];
        final chapterPosts = repo.getPosts().where((post) {
          return post.tags.any((tag) => 
            chapterTags.any((chapterTag) => 
              tag.toLowerCase().contains(chapterTag.toLowerCase())
            )
          );
        }).toList();

        if (chapterPosts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.article_outlined,
                  size: 64,
                  color: theme.colorScheme.onSurface.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No chapter posts yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Posts with chapter-related tags will appear here',
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final newPost = await Navigator.push<Post>(
                      context,
                      SlideUpPageRoute(page: const CreatePostPage()),
                    );
                    if (newPost != null && context.mounted) {
                      repo.addPost(newPost);
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Post'),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Create post button
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.dividerColor,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () async {
                  final newPost = await Navigator.push<Post>(
                    context,
                    SlideUpPageRoute(page: const CreatePostPage()),
                  );
                  if (newPost != null && context.mounted) {
                    repo.addPost(newPost);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      const SizedBox(width: 12),
                      Text(
                        'Share a chapter update...',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Posts list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 80, top: 8),
                itemCount: chapterPosts.length,
                itemBuilder: (context, index) {
                  final post = chapterPosts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: PostCard(
                      post: post,
                      onLike: () {
                        final authService = context.read<AuthService>();
                        final userProvider = context.read<UserProvider>();
                        repo.toggleLike(
                          post.id, 
                          autoSave: settings.autoSaveOnLike,
                          currentUserId: authService.user?.uid,
                          currentUserName: userProvider.displayName.isNotEmpty ? userProvider.displayName : 'You',
                          currentUserHandle: (userProvider.username != null && userProvider.username!.isNotEmpty) ? '@${userProvider.username}' : '@you',
                        );
                      },
                      onComments: () async {
                        final updated = await Navigator.push<Post>(
                          context,
                          SlideUpPageRoute(page: PostDetailPage(post: post)),
                        );
                        if (updated != null) {
                          repo.updatePost(updated);
                        }
                      },
                      onMenuSelected: (value) async {
                        if (value == 'Delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Post'),
                              content: const Text('Are you sure you want to delete this post?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true && context.mounted) {
                            final success = repo.deletePost(post.id);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Post deleted'),
                                  backgroundColor: Colors.grey[800],
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        } else if (value == 'Report') {
                          // Report functionality
                          final reasons = [
                            'Spam or misleading',
                            'Harassment or bullying',
                            'Inappropriate content',
                            'False information',
                            'Other',
                          ];
                          String? selectedReason;
                          final reasonController = TextEditingController();

                          final reported = await showDialog<bool>(
                            context: context,
                            builder: (dialogContext) => StatefulBuilder(
                              builder: (context, setState) => AlertDialog(
                                title: const Text('Report Post'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Why are you reporting this post?'),
                                      const SizedBox(height: 16),
                                      ...reasons.map((reason) => RadioListTile<String>(
                                        title: Text(reason),
                                        value: reason,
                                        groupValue: selectedReason,
                                        onChanged: (value) {
                                          setState(() => selectedReason = value);
                                        },
                                      )).toList(),
                                      if (selectedReason == 'Other') ...[
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: reasonController,
                                          decoration: const InputDecoration(
                                            labelText: 'Please specify',
                                            border: OutlineInputBorder(),
                                          ),
                                          maxLines: 3,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dialogContext, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: selectedReason != null
                                      ? () => Navigator.pop(dialogContext, true)
                                      : null,
                                    style: TextButton.styleFrom(
                                      foregroundColor: Theme.of(context).colorScheme.error,
                                    ),
                                    child: const Text('Report'),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (reported == true && context.mounted) {
                            final userId = authService.user?.uid ?? 'guest';
                            final reason = selectedReason == 'Other'
                              ? reasonController.text.trim()
                              : selectedReason!;

                            final success = await repo.reportPost(post.id, reason, userId);

                            if (success && context.mounted) {
                              final hidePost = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Report Submitted'),
                                  content: const Text(
                                    'Thank you for reporting this post. Our team will review it shortly.\n\nWould you like to hide this post from your feed?'
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('No'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Yes, Hide Post'),
                                    ),
                                  ],
                                ),
                              );

                              if (hidePost == true && context.mounted) {
                                repo.hidePost(post.id, userId);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Post hidden'),
                                    backgroundColor: Colors.grey[800],
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        } else if (value == 'Share') {
                          // Show platform selection dialog
                          final platform = await showDialog<String>(
                            context: context,
                            builder: (dialogContext) => const _SharePlatformDialog(),
                          );
                          
                          if (platform != null && context.mounted) {
                            // Show success message based on selected platform
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    const SizedBox(width: 12),
                                    Text('Shared to $platform!'),
                                  ],
                                ),
                                backgroundColor: Colors.green[700],
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('$value on post ${post.id}'),
                              backgroundColor: Colors.grey[800],
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildResourcesView(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Official FBLA Rules Section
          _buildResourceSection(
            theme: theme,
            title: '📜 Official FBLA Rules & Guidelines',
            icon: Icons.gavel,
            iconColor: Colors.red,
            resources: [
              ResourceLink(
                title: 'FBLA-PBL Bylaws',
                url: 'https://www.fbla-pbl.org/bylaws',
                description: 'Official organizational bylaws and governance',
              ),
              ResourceLink(
                title: 'Competitive Events Guidelines',
                url: 'https://www.fbla.org/compete/guidelines',
                description: 'Rules and regulations for all competitive events',
              ),
              ResourceLink(
                title: 'Code of Conduct',
                url: 'https://www.fbla.org/code-of-conduct',
                description: 'Expected behavior and professional standards',
              ),
              ResourceLink(
                title: 'Dress Code Requirements',
                url: 'https://www.fbla.org/dress-code',
                description: 'Business attire guidelines for competitions',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Getting Started Section
          _buildResourceSection(
            theme: theme,
            title: '🚀 Getting Started with FBLA',
            icon: Icons.rocket_launch,
            iconColor: Colors.blue,
            resources: [
              ResourceLink(
                title: 'New Member Guide',
                url: 'https://www.fbla.org/new-members',
                description: 'Everything you need to know as a new member',
              ),
              ResourceLink(
                title: 'How to Choose Your Event',
                url: 'https://www.fbla.org/choose-event',
                description: 'Find the perfect competitive event for your skills',
              ),
              ResourceLink(
                title: 'FBLA Membership Benefits',
                url: 'https://www.fbla.org/benefits',
                description: 'Scholarships, networking, and career opportunities',
              ),
              ResourceLink(
                title: 'Chapter Officer Handbook',
                url: 'https://www.fbla.org/officers',
                description: 'Resources for chapter leaders',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Business Plan Events
          _buildResourceSection(
            theme: theme,
            title: '💼 Business Plan Events',
            icon: Icons.business_center,
            iconColor: Colors.green,
            resources: [
              ResourceLink(
                title: 'Business Plan Template',
                url: 'https://www.fbla.org/business-plan-template',
                description: 'Official template and format guidelines',
              ),
              ResourceLink(
                title: 'Sample Winning Business Plans',
                url: 'https://www.fbla.org/sample-plans',
                description: 'Examples from past national winners',
              ),
              ResourceLink(
                title: 'Market Research Tools',
                url: 'https://www.census.gov/data',
                description: 'U.S. Census data for market analysis',
              ),
              ResourceLink(
                title: 'Financial Projection Guide',
                url: 'https://www.fbla.org/financial-projections',
                description: 'Creating realistic financial forecasts',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Presentation Events
          _buildResourceSection(
            theme: theme,
            title: '🎤 Presentation Events',
            icon: Icons.co_present,
            iconColor: Colors.purple,
            resources: [
              ResourceLink(
                title: 'Presentation Skills Guide',
                url: 'https://www.fbla.org/presentation-tips',
                description: 'Tips for delivering effective presentations',
              ),
              ResourceLink(
                title: 'PowerPoint Best Practices',
                url: 'https://www.fbla.org/powerpoint-guide',
                description: 'Creating professional slides',
              ),
              ResourceLink(
                title: 'Public Speaking Resources',
                url: 'https://www.toastmasters.org/resources',
                description: 'Toastmasters public speaking tips',
              ),
              ResourceLink(
                title: 'Video Presentation Tools',
                url: 'https://www.canva.com/presentations',
                description: 'Canva templates for visual presentations',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Testing Events
          _buildResourceSection(
            theme: theme,
            title: '✍️ Testing Events',
            icon: Icons.quiz,
            iconColor: Colors.orange,
            resources: [
              ResourceLink(
                title: 'Practice Tests Library',
                url: 'https://www.fbla.org/practice-tests',
                description: 'Official practice tests for all subjects',
              ),
              ResourceLink(
                title: 'Economics Test Prep',
                url: 'https://www.khanacademy.org/economics-finance-domain',
                description: 'Khan Academy economics courses',
              ),
              ResourceLink(
                title: 'Accounting Fundamentals',
                url: 'https://www.accountingcoach.com',
                description: 'Free accounting tutorials and practice',
              ),
              ResourceLink(
                title: 'Business Math Review',
                url: 'https://www.fbla.org/business-math',
                description: 'Key formulas and practice problems',
              ),
              ResourceLink(
                title: 'Quizlet FBLA Study Sets',
                url: 'https://quizlet.com/subject/fbla',
                description: 'Flashcards created by FBLA students',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Technology Events
          _buildResourceSection(
            theme: theme,
            title: '💻 Technology & Coding Events',
            icon: Icons.computer,
            iconColor: Colors.cyan,
            resources: [
              ResourceLink(
                title: 'Website Development Guide',
                url: 'https://www.w3schools.com',
                description: 'HTML, CSS, JavaScript tutorials',
              ),
              ResourceLink(
                title: 'Mobile App Development',
                url: 'https://developer.android.com/courses',
                description: 'Android app development basics',
              ),
              ResourceLink(
                title: 'Coding Challenge Practice',
                url: 'https://www.codecademy.com',
                description: 'Interactive coding lessons',
              ),
              ResourceLink(
                title: 'Database Design Resources',
                url: 'https://www.fbla.org/database-guide',
                description: 'SQL and database management',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Study Resources
          _buildResourceSection(
            theme: theme,
            title: '📚 Study Materials & Tools',
            icon: Icons.school,
            iconColor: Colors.indigo,
            resources: [
              ResourceLink(
                title: 'FBLA Study Guide',
                url: 'https://www.fbla.org/study-guide',
                description: 'Comprehensive study materials',
              ),
              ResourceLink(
                title: 'Business Terms Glossary',
                url: 'https://www.fbla.org/glossary',
                description: 'Key business terminology',
              ),
              ResourceLink(
                title: 'YouTube: FBLA Test Prep',
                url: 'https://www.youtube.com/results?search_query=fbla+test+prep',
                description: 'Video tutorials and study tips',
              ),
              ResourceLink(
                title: 'Study Group Finder',
                url: 'https://www.fbla.org/study-groups',
                description: 'Connect with other FBLA students',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Career Resources
          _buildResourceSection(
            theme: theme,
            title: '🎯 Career Development',
            icon: Icons.work,
            iconColor: Colors.teal,
            resources: [
              ResourceLink(
                title: 'Resume Building Guide',
                url: 'https://www.fbla.org/resume-guide',
                description: 'Create a professional resume',
              ),
              ResourceLink(
                title: 'Interview Preparation',
                url: 'https://www.fbla.org/interview-tips',
                description: 'Common questions and best practices',
              ),
              ResourceLink(
                title: 'LinkedIn Profile Tips',
                url: 'https://www.linkedin.com/help/linkedin/answer/a542685',
                description: 'Building your professional network',
              ),
              ResourceLink(
                title: 'Internship Opportunities',
                url: 'https://www.fbla.org/internships',
                description: 'Find business internships',
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Additional Resources
          _buildResourceSection(
            theme: theme,
            title: '🔗 Additional Resources',
            icon: Icons.link,
            iconColor: Colors.brown,
            resources: [
              ResourceLink(
                title: 'FBLA National Website',
                url: 'https://www.fbla-pbl.org',
                description: 'Main FBLA-PBL website',
              ),
              ResourceLink(
                title: 'FBLA Connect',
                url: 'https://connect.fbla.org',
                description: 'Member networking platform',
              ),
              ResourceLink(
                title: 'Scholarship Database',
                url: 'https://www.fbla.org/scholarships',
                description: 'FBLA scholarship opportunities',
              ),
              ResourceLink(
                title: 'National Leadership Conference',
                url: 'https://www.fbla.org/nlc',
                description: 'Information about nationals',
              ),
            ],
          ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
  
  Widget _buildResourceSection({
    required ThemeData theme,
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<ResourceLink> resources,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Resource links
          ...resources.asMap().entries.map((entry) {
            final index = entry.key;
            final resource = entry.value;
            final isLast = index == resources.length - 1;
            
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    // Open URL (you can use url_launcher package)
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Opening: ${resource.title}'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.open_in_new,
                            color: iconColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                resource.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                resource.description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                resource.url,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: theme.colorScheme.onSurface.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!isLast)
                  Divider(
                    height: 1,
                    indent: 72,
                    color: theme.dividerColor,
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class _SharePlatformDialog extends StatelessWidget {
  const _SharePlatformDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Share Post',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlatformOption(
            context: context,
            icon: Icons.link,
            label: 'Copy Link',
            color: Colors.blue,
            platform: 'Clipboard',
          ),
          const SizedBox(height: 8),
          _buildPlatformOption(
            context: context,
            icon: Icons.facebook,
            label: 'Facebook',
            color: Color(0xFF1877F2),
            platform: 'Facebook',
          ),
          const SizedBox(height: 8),
          _buildPlatformOption(
            context: context,
            icon: Icons.send,
            label: 'Twitter',
            color: Color(0xFF1DA1F2),
            platform: 'Twitter',
          ),
          const SizedBox(height: 8),
          _buildPlatformOption(
            context: context,
            icon: Icons.camera_alt,
            label: 'Instagram',
            color: Color(0xFFE4405F),
            platform: 'Instagram',
          ),
          const SizedBox(height: 8),
          _buildPlatformOption(
            context: context,
            icon: Icons.work,
            label: 'LinkedIn',
            color: Color(0xFF0A66C2),
            platform: 'LinkedIn',
          ),
          const SizedBox(height: 8),
          _buildPlatformOption(
            context: context,
            icon: Icons.mail,
            label: 'Email',
            color: Colors.grey[700]!,
            platform: 'Email',
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _buildPlatformOption({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String platform,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, platform),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class ResourceLink {
  final String title;
  final String url;
  final String description;

  ResourceLink({
    required this.title,
    required this.url,
    required this.description,
  });
}
