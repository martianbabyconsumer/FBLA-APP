import 'package:flutter/material.dart';

enum MessageType {
  announcement,
  message,
  eventNotification,
}

class ChapterMessage {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final List<ReactionCount> reactions;
  final List<String>? attachments;
  final bool isPinned;

  ChapterMessage({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.timestamp,
    this.type = MessageType.message,
    List<ReactionCount>? reactions,
    this.attachments,
    this.isPinned = false,
  }) : reactions = reactions ?? [];
}

class ReactionCount {
  final String emoji;
  final List<String> userIds;

  ReactionCount({
    required this.emoji,
    List<String>? userIds,
  }) : userIds = userIds ?? [];

  int get count => userIds.length;
}

class Channel {
  final String id;
  final String name;
  final IconData icon;
  final bool isAnnouncement;
  final String description;
  final bool isLocked;

  Channel({
    required this.id,
    required this.name,
    required this.icon,
    this.isAnnouncement = false,
    required this.description,
    this.isLocked = false,
  });
}
