import 'package:cloud_firestore/cloud_firestore.dart';

import 'last_message_model.dart';
import '../../domain/entities/chat_entity.dart';

class ChatModel extends ChatEntity {
  ChatModel({
    required super.chatId,
    required super.participants,
    required super.lastMessage,
    required super.typing,
    required super.blocked,
    required super.unreadCount,
    required super.createdAt,
  });

  // Called when creating a new chat
  Map<String, dynamic> toJson(String uid1, String uid2) {
    return {
      "participants": [uid1, uid2],
      "lastMessage": {
        "text": "",
        "senderId": "",
        "timestamp": FieldValue.serverTimestamp(),
      },
      "typing": {uid1: false, uid2: false},
      "blocked": {uid1: false, uid2: false},
      "unreadCount": {uid1: 0, uid2: 0},
      "createdAt": FieldValue.serverTimestamp(),
    };
  }

  factory ChatModel.fromJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatModel(
      chatId: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: LastMessageModel.fromJson(
        data['lastMessage'] as Map<String, dynamic>? ?? {},
      ),
      // Cast to Map<String, bool> safely
      typing: Map<String, bool>.from(data['typing'] ?? {}),
      blocked: Map<String, bool>.from(data['blocked'] ?? {}),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
