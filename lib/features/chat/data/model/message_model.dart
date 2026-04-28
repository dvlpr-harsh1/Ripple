import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/message_entity.dart';

class MessageModel extends MessageEntity {
  MessageModel({
    required super.id,
    required super.senderId,
    required super.text,
    required super.timestamp,
    required super.isRead,
    required super.isDeleted,
    required super.deletedFor,
  });

  Map<String, dynamic> toJson() => {
    "senderId": senderId,
    "text": text,
    "timestamp": FieldValue.serverTimestamp(),
    "isRead": false,
    "isDeleted": false,
    "deletedFor": [],
  };

  factory MessageModel.fromJson(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      deletedFor: List<String>.from(data['deletedFor'] ?? []),
    );
  }
}
