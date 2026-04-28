import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ripple/const/Strings/app_strings.dart';
import 'package:ripple/features/chat/data/model/chat_model.dart';
import 'package:ripple/features/chat/data/model/last_message_model.dart';
import 'package:ripple/features/chat/data/model/message_model.dart';

import '../../domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  final FirebaseFirestore _firestore;
  ChatRepositoryImpl({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;
  @override
  String getChatId({required String uid1, required String uid2}) {
    final sorted = [uid1, uid2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  @override
  Future<void> createChatIfNotExists({
    required String myUid,
    required String otherUid,
  }) async {
    final chatId = getChatId(uid1: myUid, uid2: otherUid);
    final chatDoc = await _firestore
        .collection(AppStrings.chatCollection)
        .doc(chatId)
        .get();

    if (!chatDoc.exists) {
      _firestore
          .collection(AppStrings.chatCollection)
          .doc(chatId)
          .set(
            ChatModel(
              chatId: chatId,
              participants: [myUid, otherUid],
              lastMessage: LastMessageModel(
                text: '',
                senderId: '',
                timestamp: DateTime.now(),
              ),
              typing: {},
              blocked: {},
              unreadCount: {},
              createdAt: DateTime.now(),
            ).toJson(myUid, otherUid),
          );
    }
  }

  @override
  Future<void> sentMessages({
    required String myUid,
    required String otherUid,
    required String text,
  }) async {
    final chatId = getChatId(uid1: myUid, uid2: otherUid);
    final chatDocRef = _firestore
        .collection(AppStrings.chatCollection)
        .doc(chatId);
    final messageRef = chatDocRef.collection(AppStrings.msgCollection).doc();

    final batch = _firestore.batch();

    batch.set(messageRef, {
      "senderId": myUid,
      "text": text,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
      "isDeleted": false,
      "deletedFor": [],
    });

    batch.update(chatDocRef, {
      "lastMessage": {
        "text": text,
        "senderId": myUid,
        "timestamp": FieldValue.serverTimestamp(),
      },
      "unreadCount.$otherUid": FieldValue.increment(1),
    });

    await batch.commit();
  }

  ///set Typing
  Future<void> setTyping({
    required String myUid,
    required String otherUid,
    required bool isTyping,
  }) async {
    final chatId = getChatId(uid1: myUid, uid2: otherUid);
    await _firestore.collection(AppStrings.chatCollection).doc(chatId).update({
      'typing.$myUid': isTyping,
    });
  }

  // markAsRead missing await batch.commit()
  Future<void> markAsRead({
    required String myUid,
    required String otherUid,
  }) async {
    final chatId = getChatId(uid1: myUid, uid2: otherUid);
    final batch = _firestore.batch();
    final chatDocRef = _firestore
        .collection(AppStrings.chatCollection)
        .doc(chatId);

    batch.update(chatDocRef, {"unreadCount.$myUid": 0});

    final unread = await chatDocRef
        .collection(AppStrings.msgCollection)
        .where("isRead", isEqualTo: false)
        .where('senderId', isEqualTo: otherUid)
        .get();

    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  Future<void> deleteMessage({
    required String myUid,
    required String otherUid,
    required String messageId,
    required bool deleteForEveryOne,
  }) async {
    final chatId = getChatId(uid1: myUid, uid2: otherUid);
    final msgDocRef = _firestore
        .collection(AppStrings.chatCollection)
        .doc(chatId)
        .collection(AppStrings.msgCollection)
        .doc(messageId);

    if (deleteForEveryOne) {
      await msgDocRef.update({'isDeleted': true, 'text': ''});
    } else {
      await msgDocRef.update({
        'deletedFor': FieldValue.arrayUnion([myUid]),
      });
    }
  }

  Stream<Map<String, dynamic>> getChatDocStream({
    required String myUid,
    required String otherUid,
  }) {
    final chatId = getChatId(uid1: myUid, uid2: otherUid);
    return _firestore
        .collection(AppStrings.chatCollection)
        .doc(chatId)
        .snapshots()
        .map((doc) => doc.data() as Map<String, dynamic>? ?? {});
  }

  Stream<Map<String, dynamic>> getUserDocStream({required String otherUid}) {
    return _firestore
        .collection(AppStrings.firebaseCollection)
        .doc(otherUid)
        .snapshots()
        .map((doc) => doc.data() as Map<String, dynamic>? ?? {});
  }

  // ToggleBlock reads current value first
  Future<void> toggleBlock({
    required String myUid,
    required String otherUid,
  }) async {
    final chatId = getChatId(uid1: myUid, uid2: otherUid);
    final chatDocRef = _firestore
        .collection(AppStrings.chatCollection)
        .doc(chatId);

    final doc = await chatDocRef.get();
    final blocked = Map<String, bool>.from(
      (doc.data() as Map<String, dynamic>)['blocked'] ?? {},
    );
    final current = blocked[myUid] ?? false;

    await chatDocRef.update({
      'blocked.$myUid': !current, // ✅ actually toggles
    });
  }

  /// Dashboard Chat Card
  Stream<List<ChatModel>> getChats({required String myUid}) {
    return _firestore
        .collection(AppStrings.chatCollection)
        .where('participants', arrayContains: myUid)
        .orderBy('lastMessage.timestamp', descending: true)
        .snapshots()
        .map(
          (snaps) => snaps.docs.map((doc) => ChatModel.fromJson(doc)).toList(),
        );
  }

  /// Chat Messages
  Stream<List<MessageModel>> getMessages({
    required String myUid,
    required String otherUid,
  }) {
    final chatId = getChatId(uid1: myUid, uid2: otherUid);
    return _firestore
        .collection(AppStrings.chatCollection) // ✅
        .doc(chatId)
        .collection(AppStrings.msgCollection) // ✅
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MessageModel.fromJson(doc))
              .where((msg) => !msg.isDeletedFor(myUid))
              .toList(),
        );
  }
}
