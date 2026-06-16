class MutedChatModel {
  final int? id;
  final int chatId;
  final String? mutedUntil;
  final bool isMuted;

  const MutedChatModel({
    this.id,
    required this.chatId,
    this.mutedUntil,
    this.isMuted = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'muted_until': mutedUntil,
        'is_muted': isMuted ? 1 : 0,
      };

  factory MutedChatModel.fromMap(Map<String, dynamic> map) => MutedChatModel(
        id: map['id'] as int?,
        chatId: map['chat_id'] as int,
        mutedUntil: map['muted_until'] as String?,
        isMuted: (map['is_muted'] as int? ?? 1) == 1,
      );
}
