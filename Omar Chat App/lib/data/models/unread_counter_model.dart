class UnreadCounterModel {
  final int? id;
  final int chatId;
  final int userId;
  final int unreadCount;
  final int? lastReadMessageId;

  const UnreadCounterModel({
    this.id,
    required this.chatId,
    required this.userId,
    this.unreadCount = 0,
    this.lastReadMessageId,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'user_id': userId,
        'unread_count': unreadCount,
        'last_read_message_id': lastReadMessageId,
      };

  factory UnreadCounterModel.fromMap(Map<String, dynamic> map) =>
      UnreadCounterModel(
        id: map['id'] as int?,
        chatId: map['chat_id'] as int,
        userId: map['user_id'] as int,
        unreadCount: map['unread_count'] as int? ?? 0,
        lastReadMessageId: map['last_read_message_id'] as int?,
      );
}
