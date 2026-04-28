import 'last_message_entity.dart';

class ChatEntity {
  final String chatId;
  final List<String> participants; // [uid1, uid2]
  final LastMessageEntity lastMessage;
  final Map<String, bool> typing; // {uid: true/false}
  final Map<String, bool> blocked; // {uid: true/false}
  final Map<String, int> unreadCount; // {uid: count}
  final DateTime createdAt;

  ChatEntity({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.typing,
    required this.blocked,
    required this.unreadCount,
    required this.createdAt,
  });
  // Represents chats/{chatId} document

  // Helper — get other person's uid from participants
  String otherUserId(String myUid) =>
      participants.firstWhere((id) => id != myUid);

  // Helper — am I blocked by the other person?
  bool isBlockedBy(String myUid) => blocked[myUid] ?? false;

  // Helper — is other person typing?
  bool isOtherTyping(String myUid) => typing[otherUserId(myUid)] ?? false;

  // Helper — my unread count in this chat
  int myUnreadCount(String myUid) => unreadCount[myUid] ?? 0;
}
