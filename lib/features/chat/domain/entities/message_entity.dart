class MessageEntity {
  final String id;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final bool isDeleted;
  final List<String> deletedFor;

  MessageEntity({
    required this.id,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
    required this.isDeleted,
    required this.deletedFor,
  });

  bool isDeletedFor(String uid) => deletedFor.contains(uid);
  bool isMine(String myUid) => senderId == myUid;  
}