class MessageModel {
  final int? id;
  final int chatId;
  final int senderId;
  final String? content;
  final String messageType;
  final int? replyToMessageId;
  final bool isEdited;
  final String? createdAt;
  final String? editedAt;
  final String? deletedAt;
  final bool isDeleted;
  final bool isForAll;
  final String? readAt;

  const MessageModel({
    this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.messageType = 'text',
    this.replyToMessageId,
    this.isEdited = false,
    this.createdAt,
    this.editedAt,
    this.deletedAt,
    this.isDeleted = false,
    this.isForAll = false,
    this.readAt,
  });

  static const String typeText = 'text';
  static const String typeVoice = 'voice';
  static const String typeFile = 'file';
  static const String typeImage = 'image';
  static const String typeDrawing = 'drawing';

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType,
        'reply_to_message_id': replyToMessageId,
        'is_edited': isEdited ? 1 : 0,
        'created_at': createdAt,
        'edited_at': editedAt,
        'deleted_at': deletedAt,
        'is_deleted': isDeleted ? 1 : 0,
        'is_for_all': isForAll ? 1 : 0,
        'read_at': readAt,
      };

  factory MessageModel.fromMap(Map<String, dynamic> map) => MessageModel(
        id: map['id'] as int?,
        chatId: map['chat_id'] as int,
        senderId: map['sender_id'] as int,
        content: map['content'] as String?,
        messageType: map['message_type'] as String? ?? typeText,
        replyToMessageId: map['reply_to_message_id'] as int?,
        isEdited: (map['is_edited'] as int? ?? 0) == 1,
        createdAt: map['created_at'] as String?,
        editedAt: map['edited_at'] as String?,
        deletedAt: map['deleted_at'] as String?,
        isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
        isForAll: (map['is_for_all'] as int? ?? 0) == 1,
        readAt: map['read_at'] as String?,
      );

  MessageModel copyWith({
    int? id,
    int? chatId,
    int? senderId,
    String? content,
    String? messageType,
    int? replyToMessageId,
    bool? isEdited,
    String? createdAt,
    String? editedAt,
    String? deletedAt,
    bool? isDeleted,
    bool? isForAll,
    String? readAt,
  }) =>
      MessageModel(
        id: id ?? this.id,
        chatId: chatId ?? this.chatId,
        senderId: senderId ?? this.senderId,
        content: content ?? this.content,
        messageType: messageType ?? this.messageType,
        replyToMessageId: replyToMessageId ?? this.replyToMessageId,
        isEdited: isEdited ?? this.isEdited,
        createdAt: createdAt ?? this.createdAt,
        editedAt: editedAt ?? this.editedAt,
        deletedAt: deletedAt ?? this.deletedAt,
        isDeleted: isDeleted ?? this.isDeleted,
        isForAll: isForAll ?? this.isForAll,
        readAt: readAt ?? this.readAt,
      );
}
