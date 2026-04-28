// Represents chats/{chatId}/lastMessage object
import 'package:cloud_firestore/cloud_firestore.dart';

class LastMessageEntity {
  final String text;
  final String senderId;
  final DateTime timestamp;

  LastMessageEntity({
    required this.text,
    required this.senderId,
    required this.timestamp,
  });
}
