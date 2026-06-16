import '../database/app_database.dart';
import '../models/theme_setting_model.dart';
import '../models/blocked_user_model.dart';
import '../models/muted_chat_model.dart';
import '../../core/utils/date_time_utils.dart';

class SettingsDao {
  final _store = AppDatabase.instance.store;

  Future<void> setTheme(ThemeSettingModel setting) async {
    await AppDatabase.instance.initialize();
    final existing = _store.query('theme_settings', where: (r) => r['chat_id'] == setting.chatId);
    if (existing.isEmpty) {
      await _store.insert('theme_settings', setting.toMap());
    } else {
      await _store.updateWhere(
        'theme_settings',
        setting.toMap(),
        test: (r) => r['chat_id'] == setting.chatId,
      );
    }
  }

  Future<ThemeSettingModel?> getTheme(int chatId) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query('theme_settings', where: (r) => r['chat_id'] == chatId);
    if (rows.isEmpty) return null;
    return ThemeSettingModel.fromMap(rows.first);
  }

  Future<void> blockUser(BlockedUserModel block) async {
    await AppDatabase.instance.initialize();
    final exists = _store.blockedUsers.any((r) =>
        r['blocker_user_id'] == block.blockerUserId &&
        r['blocked_user_id'] == block.blockedUserId);
    if (exists) return;
    await _store.insert('blocked_users', block.toMap());
  }

  Future<void> unblockUser(int blockerId, int blockedId) async {
    await AppDatabase.instance.initialize();
    await _store.deleteWhere(
      'blocked_users',
      test: (r) => r['blocker_user_id'] == blockerId && r['blocked_user_id'] == blockedId,
    );
  }

  /// True when [blockerId] has blocked [blockedId] (one direction only).
  Future<bool> hasBlocked(int blockerId, int blockedId) async {
    await AppDatabase.instance.initialize();
    return _store.blockedUsers.any((r) =>
        r['blocker_user_id'] == blockerId && r['blocked_user_id'] == blockedId);
  }

  /// True when either user blocked the other (used for direct messaging).
  Future<bool> isBlocked(int userId1, int userId2) async {
    return (await hasBlocked(userId1, userId2)) || (await hasBlocked(userId2, userId1));
  }

  Future<void> muteChat(MutedChatModel mute) async {
    await AppDatabase.instance.initialize();
    final existing = _store.query('muted_chats', where: (r) => r['chat_id'] == mute.chatId);
    if (existing.isEmpty) {
      await _store.insert('muted_chats', mute.toMap());
    } else {
      await _store.updateWhere(
        'muted_chats',
        mute.toMap(),
        test: (r) => r['chat_id'] == mute.chatId,
      );
    }
  }

  Future<void> unmuteChat(int chatId) async {
    await AppDatabase.instance.initialize();
    await _store.deleteWhere('muted_chats', test: (r) => r['chat_id'] == chatId);
  }

  Future<bool> isMuted(int chatId) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query(
      'muted_chats',
      where: (r) => r['chat_id'] == chatId && (r['is_muted'] as int? ?? 1) == 1,
    );
    if (rows.isEmpty) return false;
    final until = rows.first['muted_until'] as String?;
    if (until == null) return true;
    final expiry = DateTimeUtils.parseIso(until);
    if (expiry == null) return true;
    return DateTime.now().isBefore(expiry);
  }
}
