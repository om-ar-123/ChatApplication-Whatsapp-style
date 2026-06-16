class ChatModel {
  final int? id;
  final String chatType;
  final String? title;
  final String? lastMessage;
  final String? lastMessageTime;
  final String? backgroundPath;
  final String? createdAt;

  const ChatModel({
    this.id,
    required this.chatType,
    this.title,
    this.lastMessage,
    this.lastMessageTime,
    this.backgroundPath,
    this.createdAt,
  });

  static const String typeDirect = 'direct';
  static const String typeGroup = 'group';

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_type': chatType,
        'title': title,
        'last_message': lastMessage,
        'last_message_time': lastMessageTime,
        'background_path': backgroundPath,
        'created_at': createdAt,
      };

  factory ChatModel.fromMap(Map<String, dynamic> map) => ChatModel(
        id: map['id'] as int?,
        chatType: map['chat_type'] as String,
        title: map['title'] as String?,
        lastMessage: map['last_message'] as String?,
        lastMessageTime: map['last_message_time'] as String?,
        backgroundPath: map['background_path'] as String?,
        createdAt: map['created_at'] as String?,
      );

  ChatModel copyWith({
    int? id,
    String? chatType,
    String? title,
    String? lastMessage,
    String? lastMessageTime,
    String? backgroundPath,
    String? createdAt,
  }) =>
      ChatModel(
        id: id ?? this.id,
        chatType: chatType ?? this.chatType,
        title: title ?? this.title,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        backgroundPath: backgroundPath ?? this.backgroundPath,
        createdAt: createdAt ?? this.createdAt,
      );
}
