import '../database/app_database.dart';
import '../models/message_model.dart';

class MessageDao {
  final _store = AppDatabase.instance.store;

  Future<int> insert(MessageModel message) async {
    await AppDatabase.instance.initialize();
    return _store.insert('messages', message.toMap());
  }

  Future<int> update(MessageModel message) async {
    await AppDatabase.instance.initialize();
    return _store.update('messages', message.toMap(), id: message.id!);
  }

  Future<MessageModel?> getById(int id) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query('messages', where: (r) => r['id'] == id);
    if (rows.isEmpty) return null;
    return MessageModel.fromMap(rows.first);
  }

  Future<List<MessageModel>> getByChatId(int chatId) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query(
      'messages',
      where: (r) => r['chat_id'] == chatId,
      compare: (a, b) => (a['created_at'] as String? ?? '').compareTo(b['created_at'] as String? ?? ''),
    );
    return rows.map(MessageModel.fromMap).toList();
  }

  Future<List<MessageModel>> searchGlobal(String query) async {
    await AppDatabase.instance.initialize();
    final q = query.toLowerCase();
    final rows = _store.query(
      'messages',
      where: (r) => (r['is_deleted'] as int? ?? 0) == 0 && (r['content'] as String? ?? '').toLowerCase().contains(q),
      compare: (a, b) => (b['created_at'] as String? ?? '').compareTo(a['created_at'] as String? ?? ''),
    );
    return rows.map(MessageModel.fromMap).toList();
  }

  Future<List<MessageModel>> searchInChat(int chatId, String query) async {
    await AppDatabase.instance.initialize();
    final q = query.toLowerCase();
    final rows = _store.query(
      'messages',
      where: (r) =>
          r['chat_id'] == chatId &&
          (r['is_deleted'] as int? ?? 0) == 0 &&
          (r['content'] as String? ?? '').toLowerCase().contains(q),
      compare: (a, b) => (b['created_at'] as String? ?? '').compareTo(a['created_at'] as String? ?? ''),
    );
    return rows.map(MessageModel.fromMap).toList();
  }
}
