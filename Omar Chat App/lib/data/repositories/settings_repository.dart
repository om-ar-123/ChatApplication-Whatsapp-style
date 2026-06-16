import '../dao/settings_dao.dart';
import '../dao/unread_dao.dart';
import '../models/theme_setting_model.dart';
import '../models/blocked_user_model.dart';
import '../models/muted_chat_model.dart';
import '../../core/utils/date_time_utils.dart';

class SettingsRepository {
  SettingsRepository({SettingsDao? settingsDao, UnreadDao? unreadDao})
      : _settingsDao = settingsDao ?? SettingsDao(),
        _unreadDao = unreadDao ?? UnreadDao();

  final SettingsDao _settingsDao;
  final UnreadDao _unreadDao;

  Future<void> setChatTheme(int chatId, String themeName, {String? backgroundPath}) {
    return _settingsDao.setTheme(ThemeSettingModel(
      chatId: chatId,
      themeName: themeName,
      backgroundPath: backgroundPath,
    ));
  }

  Future<ThemeSettingModel?> getChatTheme(int chatId) => _settingsDao.getTheme(chatId);

  Future<void> blockUser(int blockerId, int blockedId) {
    return _settingsDao.blockUser(BlockedUserModel(
      blockerUserId: blockerId,
      blockedUserId: blockedId,
      createdAt: DateTimeUtils.nowIso(),
    ));
  }

  Future<void> unblockUser(int blockerId, int blockedId) =>
      _settingsDao.unblockUser(blockerId, blockedId);

  Future<bool> isBlocked(int userId1, int userId2) =>
      _settingsDao.isBlocked(userId1, userId2);

  Future<bool> hasBlocked(int blockerId, int blockedId) =>
      _settingsDao.hasBlocked(blockerId, blockedId);

  Future<void> muteChat(int chatId, {DateTime? until}) {
    return _settingsDao.muteChat(MutedChatModel(
      chatId: chatId,
      mutedUntil: until?.toUtc().toIso8601String(),
      isMuted: true,
    ));
  }

  Future<void> unmuteChat(int chatId) => _settingsDao.unmuteChat(chatId);

  Future<bool> isMuted(int chatId) => _settingsDao.isMuted(chatId);

  Future<void> incrementUnread(int chatId, int userId) =>
      _unreadDao.increment(chatId, userId);

  Future<void> resetUnread(int chatId, int userId, {int? lastMessageId}) =>
      _unreadDao.reset(chatId, userId, lastMessageId: lastMessageId);

  Future<int> getUnreadCount(int chatId, int userId) =>
      _unreadDao.getCount(chatId, userId);

  Future<int> getTotalUnread(int userId) => _unreadDao.getTotalForUser(userId);
}
