import '../../domain/entities/group.dart';
import '../dao/group_dao.dart';
import '../dao/chat_dao.dart';

class GroupRepository {
  GroupRepository({GroupDao? groupDao, ChatDao? chatDao})
      : _groupDao = groupDao ?? GroupDao(),
        _chatDao = chatDao ?? ChatDao();

  final GroupDao _groupDao;
  final ChatDao _chatDao;

  Future<int> createGroup(String title, List<int> memberIds) =>
      _groupDao.createGroup(title, memberIds);

  Future<Group?> getGroup(int chatId) async {
    final chat = await _chatDao.getById(chatId);
    if (chat == null || chat.id == null) return null;
    final members = await _groupDao.getMemberUserIds(chatId);
    return Group(chatId: chat.id!, name: chat.title ?? 'Group', memberIds: members);
  }

  Future<List<int>> getMemberIds(int chatId) => _groupDao.getMemberUserIds(chatId);
}
