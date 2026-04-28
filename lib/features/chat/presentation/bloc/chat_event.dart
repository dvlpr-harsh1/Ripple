import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatInitialized extends ChatEvent {
  final String myUid;
  final String otherUid;
    ChatInitialized({required this.myUid, required this.otherUid});
  @override
  List<Object?> get props => [myUid, otherUid];
}

class ChatMessageSent extends ChatEvent {
  final String myUid;
  final String otherUid;
  final String text;
    ChatMessageSent({
    required this.myUid,
    required this.otherUid,
    required this.text,
  });
  @override
  List<Object?> get props => [myUid, otherUid, text];
}

class ChatTypingChanged extends ChatEvent {
  final String myUid;
  final String otherUid;
  final bool isTyping;
    ChatTypingChanged({
    required this.myUid,
    required this.otherUid,
    required this.isTyping,
  });
  @override
  List<Object?> get props => [myUid, otherUid, isTyping];
}

class ChatMessageDeleted extends ChatEvent {
  final String myUid;
  final String otherUid;
  final String messageId;
  final bool forEveryone;
    ChatMessageDeleted({
    required this.myUid,
    required this.otherUid,
    required this.messageId,
    required this.forEveryone,
  });
  @override
  List<Object?> get props => [myUid, otherUid, messageId, forEveryone];
}

class ChatMarkedAsRead extends ChatEvent {
  final String myUid;
  final String otherUid;
    ChatMarkedAsRead({required this.myUid, required this.otherUid});
  @override
  List<Object?> get props => [myUid, otherUid];
}

// ✅ New — fired when chat doc stream emits (typing changes)
class ChatDocUpdated extends ChatEvent {
  final Map<String, dynamic> chatData;
    ChatDocUpdated({required this.chatData});
  @override
  List<Object?> get props => [chatData];
}

// ✅ New — fired when user doc stream emits (online status changes)
class ChatUserDocUpdated extends ChatEvent {
  final Map<String, dynamic> userData;
    ChatUserDocUpdated({required this.userData});
  @override
  List<Object?> get props => [userData];
}