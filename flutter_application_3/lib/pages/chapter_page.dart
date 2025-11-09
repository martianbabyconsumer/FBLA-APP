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
  bool _showEmojiPicker = false;

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
    // In a real app, this would load messages from a backend
    final now = DateTime.now();
    _messages = [
      ChapterMessage(
        id: '1',
        authorId: 'advisor',
        authorName: 'Chapter Advisor',
        content:
            '🎉 Welcome to our FBLA Chapter! This is our new communication platform. Please read the rules and guidelines pinned in the announcements channel.',
        timestamp: now.subtract(const Duration(days: 1)),
        type: MessageType.announcement,
        isPinned: true,
      ),
      ChapterMessage(
        id: '2',
        authorId: 'president',
        authorName: 'Chapter President',
        content:
            'Our next meeting will be on Friday at 3:30 PM in Room 201. We\'ll be discussing upcoming competition preparations!',
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
                      return ListTile(
                        leading: Icon(
                          channel.icon,
                          color: isSelected
                              ? theme.primaryColor
                              : theme.unselectedWidgetColor,
                        ),
                        title: Text(
                          '#${channel.name}',
                          style: TextStyle(
                            color: isSelected
                                ? theme.primaryColor
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
                // Content area - show calendar, posts, or messages based on channel
                Expanded(
                  child: _selectedChannel.id == 'chapter-calendar'
                      ? _buildCalendarView(theme)
                      : _selectedChannel.id == 'chapter-posts'
                        ? _buildPostsFeedView(theme)
                        : _buildMessagesView(theme),
                ),
                // Message input
                if (!_selectedChannel.isLocked &&
                    _selectedChannel.id != 'chapter-calendar')
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
                  CircleAvatar(
                    backgroundColor: theme.primaryColor,
                    child: Text(
                      message.authorName[0],
                      style: TextStyle(color: theme.colorScheme.onPrimary),
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
