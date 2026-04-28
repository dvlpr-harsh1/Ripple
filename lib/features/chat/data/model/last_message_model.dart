import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/last_message_entity.dart';

class LastMessageModel extends LastMessageEntity {
  LastMessageModel({
    required super.text,
    required super.senderId,
    required super.timestamp,
    required super.isDeleted, 
  });

  Map<String, dynamic> toJson() => {
    'text': text,
    'senderId': senderId,
    'timestamp': FieldValue.serverTimestamp(),
    'isDeleted': isDeleted,
  };

  factory LastMessageModel.fromJson(Map<String, dynamic> data) {
    return LastMessageModel(
      text: data['text'] ?? '',
      senderId: data['senderId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] ?? false, 
    );
  }
}