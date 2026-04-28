import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/known_user_entity.dart';

class KnownUserModel extends KnownUserEntity {
  const KnownUserModel({
    required super.id,
    required super.name,
    required super.nameLower,
    required super.username,
    required super.usernameLower,
    required super.email,
    required super.imgUrl,
    required super.badge,
    required super.isOnline,
    required super.lastSeen,
    required super.createdAt,
    required super.lastMessage,
    required super.isTyping,
    required super.isBlocked,
    required super.receivedMessagesCount,
    required super.receivedMessagesTime,
  });

  // ── called on signup — writes to users/{uid} ──────
  static Map<String, dynamic> toSignupJson({
    required String id,
    required String name,
    required String username,
    required String email,
  }) {
    return {
      "id": id,
      "name": name,
      "nameLower": name.toLowerCase(),
      "username": username,
      "usernameLower": username.toLowerCase(),
      "email": email,
      "imgUrl": "",
      "badge": "",
      "isOnline": true,
      "lastSeen": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
    };
  }

  factory KnownUserModel.fromMerged({
    required DocumentSnapshot userDoc,
    required DocumentSnapshot chatDoc,
    required String myUid,
  }) {
    final u = userDoc.data() as Map<String, dynamic>;
    final c = chatDoc.data() as Map<String, dynamic>;

    final lastMsg = c['lastMessage'] as Map<String, dynamic>? ?? {};
    final unreadCount = Map<String, int>.from(c['unreadCount'] ?? {});
    final typing = Map<String, bool>.from(c['typing'] ?? {});
    final blocked = Map<String, bool>.from(c['blocked'] ?? {});

    // Other person's uid
    final participants = List<String>.from(c['participants'] ?? []);
    final otherUid = participants.firstWhere(
      (id) => id != myUid,
      orElse: () => '',
    );

    // Format timestamp → "10:32"
    final msgTimestamp = (lastMsg['timestamp'] as Timestamp?)?.toDate();
    final timeString = msgTimestamp != null
        ? '${msgTimestamp.hour.toString().padLeft(2, '0')}:'
              '${msgTimestamp.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return KnownUserModel(
      // from users/
      id: userDoc.id,
      name: u['name'] ?? '',
      nameLower: u['nameLower'] ?? '',
      username: u['username'] ?? '',
      usernameLower: u['usernameLower'] ?? '',
      email: u['email'] ?? '',
      imgUrl: u['imgUrl'] ?? '',
      badge: u['badge'] ?? '',
      isOnline: u['isOnline'] ?? false,
      lastSeen: (u['lastSeen'] as Timestamp?)?.toDate(),
      createdAt: (u['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),

      // from chats/
      lastMessage: lastMsg['text'] ?? '',
      isTyping: typing[otherUid] ?? false, // other person typing
      isBlocked: blocked[myUid] ?? false, // am I blocked
      receivedMessagesCount: unreadCount[myUid] ?? 0, // my unread count
      receivedMessagesTime: timeString, // formatted time
    );
  }



}
