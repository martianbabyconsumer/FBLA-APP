import 'package:flutter/material.dart';
import '../models/event.dart';

class CalendarProvider extends ChangeNotifier {
  final Map<DateTime, List<Event>> _personalEvents = {};
  final Map<DateTime, List<Event>> _chapterEvents = {};

  CalendarProvider() {
    _initializeSampleEvents();
  }

  void _initializeSampleEvents() {
    final now = DateTime.now();

    // Chapter events - FBLA themed
    _chapterEvents[DateTime(2025, 11, 12)] = [
      Event(
        title: 'Area at JVHS',
        description: 'Area Competition at Junction View High School - All competitive events',
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 15, minute: 0),
        color: Colors.red,
      ),
    ];

    // Add FBLA Meetings every other Wednesday
    // Find the next Wednesday
    DateTime currentDate = DateTime(now.year, now.month, now.day);
    int daysUntilWednesday = (DateTime.wednesday - currentDate.weekday) % 7;
    if (daysUntilWednesday == 0) daysUntilWednesday = 7; // If today is Wednesday, get next Wednesday
    DateTime nextWednesday = currentDate.add(Duration(days: daysUntilWednesday));
    
    // Add 6 FBLA Meetings, every other Wednesday (14 days apart)
    for (int i = 0; i < 6; i++) {
      DateTime meetingDate = nextWednesday.add(Duration(days: i * 14));
      _chapterEvents[meetingDate] = [
        Event(
          title: 'FBLA Meeting',
          description: 'Bi-weekly FBLA chapter meeting in Room 201',
          startTime: const TimeOfDay(hour: 15, minute: 30),
          endTime: const TimeOfDay(hour: 16, minute: 30),
          color: Colors.blue,
        ),
      ];
    }

    _chapterEvents[DateTime(now.year, now.month, now.day + 5)] = [
      Event(
        title: 'Leadership Workshop',
        description: 'District Leadership Conference preparation',
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        color: Colors.green,
      ),
    ];

    _chapterEvents[DateTime(now.year, now.month, now.day + 7)] = [
      Event(
        title: 'Fundraiser Planning',
        description: 'Planning committee for annual FBLA fundraiser',
        startTime: const TimeOfDay(hour: 15, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 30),
        color: Colors.orange,
      ),
    ];

    _chapterEvents[DateTime(now.year, now.month, now.day + 10)] = [
      Event(
        title: 'Business Tour',
        description: 'Local business tour and networking event',
        startTime: const TimeOfDay(hour: 13, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        color: Colors.purple,
      ),
    ];

    _chapterEvents[DateTime(now.year, now.month + 1, 5)] = [
      Event(
        title: 'State Leadership Conference',
        description: 'Annual SLC - Sacramento Convention Center',
        startTime: const TimeOfDay(hour: 7, minute: 0),
        endTime: const TimeOfDay(hour: 18, minute: 0),
        color: Colors.red,
      ),
    ];

    // Personal events
    _personalEvents[DateTime(now.year, now.month, now.day + 1)] = [
      Event(
        title: 'Practice Presentation',
        description: 'Practice for Business Plan presentation',
        startTime: const TimeOfDay(hour: 16, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        color: Colors.orange,
      ),
    ];

    _personalEvents[DateTime(now.year, now.month, now.day + 3)] = [
      Event(
        title: 'Study Session',
        description: 'Competitive event exam preparation',
        startTime: const TimeOfDay(hour: 14, minute: 30),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        color: Colors.teal,
      ),
    ];
  }

  Map<DateTime, List<Event>> get personalEvents => _personalEvents;
  Map<DateTime, List<Event>> get chapterEvents => _chapterEvents;

  void addPersonalEvent(DateTime date, Event event) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_personalEvents[normalizedDate] == null) {
      _personalEvents[normalizedDate] = [event];
    } else {
      _personalEvents[normalizedDate]!.add(event);
    }
    notifyListeners();
  }

  void addChapterEvent(DateTime date, Event event) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    if (_chapterEvents[normalizedDate] == null) {
      _chapterEvents[normalizedDate] = [event];
    } else {
      _chapterEvents[normalizedDate]!.add(event);
    }
    notifyListeners();
  }

  void removePersonalEvent(DateTime date, Event event) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _personalEvents[normalizedDate]?.remove(event);
    if (_personalEvents[normalizedDate]?.isEmpty ?? false) {
      _personalEvents.remove(normalizedDate);
    }
    notifyListeners();
  }

  void removeChapterEvent(DateTime date, Event event) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    _chapterEvents[normalizedDate]?.remove(event);
    if (_chapterEvents[normalizedDate]?.isEmpty ?? false) {
      _chapterEvents.remove(normalizedDate);
    }
    notifyListeners();
  }

  List<Event> getPersonalEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _personalEvents[normalizedDay] ?? [];
  }

  List<Event> getChapterEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _chapterEvents[normalizedDay] ?? [];
  }
}
