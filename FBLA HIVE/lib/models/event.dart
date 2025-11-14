import 'package:flutter/material.dart';

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
