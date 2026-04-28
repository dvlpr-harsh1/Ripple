class KnownUserEntity {
  final String id;
  final String name;
  final String nameLower;
  final String username;
  final String usernameLower;
  final String email;
  final String imgUrl;
  final String badge;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;

  final String lastMessage;
  final bool isTyping;
  final bool isBlocked;
  final int receivedMessagesCount;
  final String receivedMessagesTime;

  final bool lastMessageDeleted;

  const KnownUserEntity({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.username,
    required this.usernameLower,
    required this.email,
    required this.imgUrl,
    required this.badge,
    required this.isOnline,
    required this.lastSeen,
    required this.createdAt,
    required this.lastMessage,
    required this.isTyping,
    required this.isBlocked,
    required this.receivedMessagesCount,
    required this.receivedMessagesTime,
    required this.lastMessageDeleted,
  });
}
