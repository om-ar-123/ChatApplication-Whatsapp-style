import '../database/app_database.dart';
import '../models/unread_counter_model.dart';

class UnreadDao {
  final _store = AppDatabase.instance.store;

  Future<void> increment(int chatId, int userId) async {
    await AppDatabase.instance.initialize();
    final existing = _store.query(
      'unread_counts',
      where: (r) => r['chat_id'] == chatId && r['user_id'] == userId,
    );
    if (existing.isEmpty) {
      await _store.insert('unread_counts', {
        'chat_id': chatId,
        'user_id': userId,
        'unread_count': 1,
      });
    } else {
      final current = existing.first['unread_count'] as int? ?? 0;
      await _store.updateWhere(
        'unread_counts',
        {'unread_count': current + 1},
        test: (r) => r['chat_id'] == chatId && r['user_id'] == userId,
      );
    }
  }

  Future<void> reset(int chatId, int userId, {int? lastMessageId}) async {
    await AppDatabase.instance.initialize();
    final existing = _store.query(
      'unread_counts',
      where: (r) => r['chat_id'] == chatId && r['user_id'] == userId,
    );
    if (existing.isEmpty) {
      await _store.insert('unread_counts', {
        'chat_id': chatId,
        'user_id': userId,
        'unread_count': 0,
        'last_read_message_id': lastMessageId,
      });
    } else {
      await _store.updateWhere(
        'unread_counts',
        {'unread_count': 0, 'last_read_message_id': lastMessageId},
        test: (r) => r['chat_id'] == chatId && r['user_id'] == userId,
      );
    }
  }

  Future<int> getCount(int chatId, int userId) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query(
      'unread_counts',
      where: (r) => r['chat_id'] == chatId && r['user_id'] == userId,
    );
    if (rows.isEmpty) return 0;
    return rows.first['unread_count'] as int? ?? 0;
  }

  Future<int> getTotalForUser(int userId) async {
    await AppDatabase.instance.initialize();
    return _store
        .query('unread_counts', where: (r) => r['user_id'] == userId)
        .fold<int>(0, (sum, r) => sum + (r['unread_count'] as int? ?? 0));
  }

  Future<UnreadCounterModel?> getCounter(int chatId, int userId) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query(
      'unread_counts',
      where: (r) => r['chat_id'] == chatId && r['user_id'] == userId,
    );
    if (rows.isEmpty) return null;
    return UnreadCounterModel.fromMap(rows.first);
  }
}
