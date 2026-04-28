// unknown_user_entity.dart
import '../../../dashboard/domain/entities/known_user_entity.dart';

class UnknownUserEntity {
  final String id;
  final String name;
  final String nameLower;
  final String username;
  final String usernameLower;
  final String imgUrl;

  UnknownUserEntity({
    required this.id,
    required this.name,
    required this.nameLower,
    required this.username,
    required this.usernameLower,
    required this.imgUrl,
  });

  // ✅ convert to KnownUserEntity with defaults for chat fields
  KnownUserEntity toKnownUser() => KnownUserEntity(
    id: id,
    name: name,
    nameLower: nameLower,
    username: username,
    usernameLower: usernameLower,
    email: '',
    imgUrl: imgUrl,
    badge: '',
    isOnline: false,
    lastSeen: null,
    createdAt: DateTime.now(),
    lastMessage: '',
    isTyping: false,
    isBlocked: false,
    lastMessageDeleted: false,
    receivedMessagesCount: 0,
    receivedMessagesTime: '--:--',
  );
}