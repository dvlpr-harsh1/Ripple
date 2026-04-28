import '../../data/model/chat_model.dart';
import '../../data/model/message_model.dart';

abstract class ChatRepository {
  String getChatId({required String uid1, required String uid2});
  
  Future<void> createChatIfNotExists({
    required String myUid,
    required String otherUid,
  });
  Future<void> sentMessages({
    required String myUid,
    required String otherUid,
    required String text,
  });
  Future<void> setTyping({
    required String myUid,
    required String otherUid,
    required bool isTyping,
  });
  Future<void> markAsRead({
    required String myUid,
    required String otherUid,
  });
  Future<void> toggleBlock({
    required String myUid,
    required String otherUid,
  });
  Future<void> deleteMessage({
    required String myUid,
    required String otherUid,
    required String messageId,
    required bool deleteForEveryOne,
  });
  Stream<List<ChatModel>> getChats({required String myUid});
  Stream<List<MessageModel>> getMessages({
    required String myUid,
    required String otherUid,
  });
}