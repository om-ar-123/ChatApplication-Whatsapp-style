class Message {
  final int id;
  final int chatId;
  final int senderId;
  final String? content;
  final String messageType;
  final int? replyToMessageId;
  final String? replyPreview;
  final bool isEdited;
  final String? createdAt;
  final String? editedAt;
  final bool isDeleted;
  final bool isForAll;
  final String? senderName;
  final String? attachmentPath;
  final String? attachmentName;

  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    required this.messageType,
    this.replyToMessageId,
    this.replyPreview,
    this.isEdited = false,
    this.createdAt,
    this.editedAt,
    this.isDeleted = false,
    this.isForAll = false,
    this.senderName,
    this.attachmentPath,
    this.attachmentName,
  });
}
