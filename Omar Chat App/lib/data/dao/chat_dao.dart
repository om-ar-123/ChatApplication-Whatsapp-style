import '../database/app_database.dart';
import '../models/chat_model.dart';

class ChatDao {
  final _store = AppDatabase.instance.store;

  Future<int> insert(ChatModel chat) async {
    await AppDatabase.instance.initialize();
    return _store.insert('chats', chat.toMap());
  }

  Future<int> update(ChatModel chat) async {
    await AppDatabase.instance.initialize();
    return _store.update('chats', chat.toMap(), id: chat.id!);
  }

  Future<ChatModel?> getById(int id) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query('chats', where: (r) => r['id'] == id);
    if (rows.isEmpty) return null;
    return ChatModel.fromMap(rows.first);
  }

  Future<List<ChatModel>> getChatsForUser(int userId) async {
    await AppDatabase.instance.initialize();
    final memberChatIds = _store
        .query('chat_members', where: (m) => m['user_id'] == userId)
        .map((m) => m['chat_id'] as int)
        .toSet();
    final rows = _store.query(
      'chats',
      where: (c) => memberChatIds.contains(c['id']),
      compare: (a, b) {
        final ta = a['last_message_time'] as String? ?? '';
        final tb = b['last_message_time'] as String? ?? '';
        return ta.compareTo(tb);
      },
      descending: true,
    );
    return rows.map(ChatModel.fromMap).toList();
  }

  Future<void> updateLastMessage(int chatId, String message, String time) async {
    await AppDatabase.instance.initialize();
    await _store.updateWhere(
      'chats',
      {'last_message': message, 'last_message_time': time},
      test: (r) => r['id'] == chatId,
    );
  }

  Future<int?> findDirectChat(int userId1, int userId2) async {
    await AppDatabase.instance.initialize();
    for (final chat in _store.query('chats', where: (c) => c['chat_type'] == ChatModel.typeDirect)) {
      final chatId = chat['id'] as int;
      final members = _store
          .query('chat_members', where: (m) => m['chat_id'] == chatId)
          .map((m) => m['user_id'] as int)
          .toSet();
      if (members.contains(userId1) && members.contains(userId2)) return chatId;
    }
    return null;
  }
}
