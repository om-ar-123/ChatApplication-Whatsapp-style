class Chat {
  final int id;
  final String chatType;
  final String title;
  final String? lastMessage;
  final String? lastMessageTime;
  final String? backgroundPath;
  final int unreadCount;
  final bool isMuted;
  final bool isBlocked;
  final String? otherUserAvatar;
  final int? otherUserId;

  const Chat({
    required this.id,
    required this.chatType,
    required this.title,
    this.lastMessage,
    this.lastMessageTime,
    this.backgroundPath,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isBlocked = false,
    this.otherUserAvatar,
    this.otherUserId,
  });
}
