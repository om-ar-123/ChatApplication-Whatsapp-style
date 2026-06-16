import 'chat_model.dart';

class ChatMemberModel {
  final int? id;
  final int chatId;
  final int userId;
  final String? role;

  const ChatMemberModel({
    this.id,
    required this.chatId,
    required this.userId,
    this.role,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'user_id': userId,
        'role': role,
      };

  factory ChatMemberModel.fromMap(Map<String, dynamic> map) => ChatMemberModel(
        id: map['id'] as int?,
        chatId: map['chat_id'] as int,
        userId: map['user_id'] as int,
        role: map['role'] as String?,
      );
}

class GroupModel {
  final ChatModel chat;
  final List<int> memberIds;

  const GroupModel({required this.chat, required this.memberIds});
}
