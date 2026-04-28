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
                isDeleted: false,
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

    final chatDocRef = _firestore
        .collection(AppStrings.chatCollection)
        .doc(chatId);

    final msgDocRef = chatDocRef
        .collection(AppStrings.msgCollection)
        .doc(messageId);

    final msgSnap = await msgDocRef.get();

    if (!msgSnap.exists) return;

    final data = msgSnap.data() as Map<String, dynamic>;

    final senderId = data['senderId'] as String? ?? '';

    final isRead = data['isRead'] as bool? ?? true;

    final shouldDecrementUnread = senderId != myUid && !isRead;

    final batch = _firestore.batch();

    if (deleteForEveryOne) {
      batch.update(msgDocRef, {'isDeleted': true, 'text': ''});
    } else {
      batch.update(msgDocRef, {
        'deletedFor': FieldValue.arrayUnion([myUid]),
      });
    }

    if (shouldDecrementUnread) {
      batch.update(chatDocRef, {
        'unreadCount.$myUid': FieldValue.increment(-1),
      });
    }

    await _refreshLastMessage(
      chatDocRef: chatDocRef,

      deletedMsgId: messageId,

      myUid: myUid,

      otherUid: otherUid,

      batch: batch,

      deleteForEveryone: deleteForEveryOne,
    );

    await batch.commit();
  }

  Future<void> _refreshLastMessage({
    required DocumentReference chatDocRef,

    required String deletedMsgId,

    required String myUid,

    required String otherUid,

    required WriteBatch batch,

    required bool deleteForEveryone,
  }) async {
    final msgs = await chatDocRef
        .collection(AppStrings.msgCollection)
        .orderBy('timestamp', descending: true)
        .limit(2)
        .get();

    if (msgs.docs.isEmpty) return;

    // Check if the deleted message is the current last message

    final isLastMessage = msgs.docs.first.id == deletedMsgId;

    if (!isLastMessage) return;

    if (msgs.docs.length == 1) {
      // Only message — clear lastMessage

      batch.update(chatDocRef, {
        'lastMessage': {
          'text': '',

          'senderId': '',

          'timestamp': FieldValue.serverTimestamp(),

          'isDeleted': false,
        },
      });

      return;
    }

    // Use second most recent message as new lastMessage

    final prevData = msgs.docs[1].data();

    final prevIsDeleted = prevData['isDeleted'] as bool? ?? false;

    batch.update(chatDocRef, {
      'lastMessage': {
        'text': prevIsDeleted ? '' : (prevData['text'] ?? ''),

        'senderId': prevData['senderId'] ?? '',

        'timestamp': prevData['timestamp'],

        'isDeleted': prevIsDeleted,
      },
    });
  }

  // ✅ If deleted message was the last message, update lastMessage to previous one
  Future<void> _updateLastMessageIfNeeded({
    required DocumentReference chatDocRef,
    required DocumentReference msgDocRef,
    required String chatId,
    required String myUid,
    required String otherUid,
    required WriteBatch batch,
  }) async {
    // Get current lastMessage
    final chatSnap = await chatDocRef.get();
    final chatData = chatSnap.data() as Map<String, dynamic>? ?? {};
    final lastMsg = chatData['lastMessage'] as Map<String, dynamic>? ?? {};
    final lastMsgSenderId = lastMsg['senderId'] as String? ?? '';

    // Check if the message being deleted is the last one
    // by seeing if its senderId matches and timestamp is close
    // Simplest: fetch the previous message and update
    final prevMessages = await chatDocRef
        .collection(AppStrings.msgCollection)
        .orderBy('timestamp', descending: true)
        .limit(
          2,
        ) // get top 2 — first is the one being deleted, second is new last
        .get();

    if (prevMessages.docs.length >= 2) {
      final newLastDoc = prevMessages.docs[1];
      final newLastData = newLastDoc.data();
      batch.update(chatDocRef, {
        'lastMessage': {
          'text': newLastData['isDeleted'] == true
              ? ''
              : (newLastData['text'] ?? ''),
          'senderId': newLastData['senderId'] ?? '',
          'timestamp': newLastData['timestamp'],
        },
      });
    } else if (prevMessages.docs.length == 1) {
      // Only one message and it's being deleted — clear lastMessage
      batch.update(chatDocRef, {
        'lastMessage': {
          'text': '',
          'senderId': '',
          'timestamp': FieldValue.serverTimestamp(),
        },
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
        .collection(AppStrings.chatCollection)
        .doc(chatId)
        .collection(AppStrings.msgCollection)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => MessageModel.fromJson(doc))
              .where((msg) => !msg.isDeletedFor(myUid))
              .toList(), // ✅ keep isDeleted=true but show deleted bubble
        );
  }
}
