class LastMessageEntity {
  final String text;
  final String senderId;
  final DateTime timestamp;
  final bool isDeleted;

  const LastMessageEntity({
    required this.text,
    required this.senderId,
    required this.timestamp,
    required this.isDeleted,
  });
}
