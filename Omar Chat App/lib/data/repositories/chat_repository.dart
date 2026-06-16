import '../../domain/entities/chat.dart';
import '../dao/chat_dao.dart';
import '../dao/group_dao.dart';
import '../dao/unread_dao.dart';
import '../dao/settings_dao.dart';
import '../dao/user_dao.dart';
import '../models/chat_model.dart';
import '../../core/utils/date_time_utils.dart';

class ChatRepository {
  ChatRepository({
    ChatDao? chatDao,
    GroupDao? groupDao,
    UnreadDao? unreadDao,
    SettingsDao? settingsDao,
    UserDao? userDao,
  })  : _chatDao = chatDao ?? ChatDao(),
        _groupDao = groupDao ?? GroupDao(),
        _unreadDao = unreadDao ?? UnreadDao(),
        _settingsDao = settingsDao ?? SettingsDao(),
        _userDao = userDao ?? UserDao();

  final ChatDao _chatDao;
  final GroupDao _groupDao;
  final UnreadDao _unreadDao;
  final SettingsDao _settingsDao;
  final UserDao _userDao;

  Future<List<Chat>> getChatsForUser(int userId) async {
    final models = await _chatDao.getChatsForUser(userId);
    final chats = <Chat>[];
    for (final model in models) {
      if (model.id == null) continue;
      final unread = await _unreadDao.getCount(model.id!, userId);
      final muted = await _settingsDao.isMuted(model.id!);
      String title = model.title ?? 'Chat';
      String? avatar;
      int? otherUserId;
      var blocked = false;

      String? preview = model.lastMessage;

      if (model.chatType == ChatModel.typeDirect) {
        final members = await _groupDao.getMemberUserIds(model.id!);
        otherUserId = members.firstWhere((id) => id != userId, orElse: () => userId);
        final other = await _userDao.getById(otherUserId);
        if (other != null) {
          title = other.name;
          avatar = other.avatarPath;
        }
        blocked = await _settingsDao.isBlocked(userId, otherUserId);
      } else if (model.chatType == ChatModel.typeGroup) {
        final members = await _groupDao.getMemberUserIds(model.id!);
        final names = <String>[];
        for (final memberId in members) {
          final user = await _userDao.getById(memberId);
          if (user != null) names.add(user.name);
        }
        final membersText = names.join(', ');
        if (membersText.isNotEmpty) {
          preview = model.lastMessage != null && model.lastMessage!.isNotEmpty
              ? '${model.lastMessage} · $membersText'
              : membersText;
        }
      }

      final theme = await _settingsDao.getTheme(model.id!);
      chats.add(Chat(
        id: model.id!,
        chatType: model.chatType,
        title: title,
        lastMessage: preview,
        lastMessageTime: model.lastMessageTime,
        backgroundPath: theme?.backgroundPath ?? model.backgroundPath,
        unreadCount: unread,
        isMuted: muted,
        isBlocked: blocked,
        otherUserAvatar: avatar,
        otherUserId: otherUserId,
      ));
    }
    return chats;
  }

  Future<int> createDirectChat(int currentUserId, int otherUserId) async {
    final existing = await _chatDao.findDirectChat(currentUserId, otherUserId);
    if (existing != null) return existing;

    final now = DateTimeUtils.nowIso();
    final other = await _userDao.getById(otherUserId);
    final chatId = await _chatDao.insert(ChatModel(
      chatType: ChatModel.typeDirect,
      title: other?.name ?? 'Chat',
      createdAt: now,
      lastMessageTime: now,
    ));
    await _groupDao.addMember(chatId, currentUserId);
    await _groupDao.addMember(chatId, otherUserId);
    return chatId;
  }

  Future<ChatModel?> getChatById(int id) => _chatDao.getById(id);

  Future<int> getTotalUnread(int userId) => _unreadDao.getTotalForUser(userId);

  Future<void> updateLastMessage(int chatId, String message) async {
    await _chatDao.updateLastMessage(chatId, message, DateTimeUtils.nowIso());
  }
}
