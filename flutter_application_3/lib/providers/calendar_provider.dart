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
    
    // Chapter events
    _chapterEvents[DateTime(now.year, now.month, now.day + 2)] = [
      Event(
        title: 'Chapter Meeting',
        description: 'Monthly FBLA chapter meeting in Room 201',
        startTime: const TimeOfDay(hour: 15, minute: 30),
        endTime: const TimeOfDay(hour: 16, minute: 30),
        color: Colors.blue,
      ),
    ];
    
    _chapterEvents[DateTime(now.year, now.month, now.day + 5)] = [
      Event(
        title: 'Leadership Conference',
        description: 'State Leadership Conference preparation meeting',
        startTime: const TimeOfDay(hour: 14, minute: 0),
        endTime: const TimeOfDay(hour: 16, minute: 0),
        color: Colors.green,
      ),
    ];

    // Personal events
    _personalEvents[DateTime(now.year, now.month, now.day + 1)] = [
      Event(
        title: 'Practice Presentation',
        description: 'Practice for upcoming competition',
        startTime: const TimeOfDay(hour: 16, minute: 0),
        endTime: const TimeOfDay(hour: 17, minute: 0),
        color: Colors.orange,
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
