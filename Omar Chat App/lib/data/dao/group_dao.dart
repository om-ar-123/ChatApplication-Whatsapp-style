import '../database/app_database.dart';
import '../models/chat_model.dart';
import '../models/group_model.dart';
import '../../core/utils/date_time_utils.dart';

class GroupDao {
  final _store = AppDatabase.instance.store;

  Future<int> createGroup(String title, List<int> memberIds) async {
    await AppDatabase.instance.initialize();
    final now = DateTimeUtils.nowIso();
    final chatId = await _store.insert('chats', {
      'chat_type': ChatModel.typeGroup,
      'title': title,
      'last_message': 'Group created',
      'created_at': now,
      'last_message_time': now,
    });
    for (var i = 0; i < memberIds.length; i++) {
      await _store.insert('chat_members', {
        'chat_id': chatId,
        'user_id': memberIds[i],
        'role': i == 0 ? 'admin' : 'member',
      });
    }
    for (final userId in memberIds) {
      await _store.insert('unread_counts', {
        'chat_id': chatId,
        'user_id': userId,
        'unread_count': 0,
      });
    }
    return chatId;
  }

  Future<List<ChatMemberModel>> getMembers(int chatId) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query('chat_members', where: (r) => r['chat_id'] == chatId);
    return rows.map(ChatMemberModel.fromMap).toList();
  }

  Future<List<int>> getMemberUserIds(int chatId) async {
    final members = await getMembers(chatId);
    return members.map((m) => m.userId).toList();
  }

  Future<void> addMember(int chatId, int userId) async {
    await AppDatabase.instance.initialize();
    await _store.insert('chat_members', {
      'chat_id': chatId,
      'user_id': userId,
      'role': 'member',
    });
  }

  Future<void> removeMember(int chatId, int userId) async {
    await AppDatabase.instance.initialize();
    await _store.deleteWhere('chat_members', test: (r) => r['chat_id'] == chatId && r['user_id'] == userId);
  }
}
