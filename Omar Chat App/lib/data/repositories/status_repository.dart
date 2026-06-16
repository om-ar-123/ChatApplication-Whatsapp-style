import '../dao/status_dao.dart';
import '../dao/user_dao.dart';
import '../models/status_model.dart';

class StatusItem {
  final StatusModel status;
  final String userName;
  final String? avatarPath;

  StatusItem({required this.status, required this.userName, this.avatarPath});
}

class StatusRepository {
  StatusRepository({StatusDao? statusDao, UserDao? userDao})
      : _statusDao = statusDao ?? StatusDao(),
        _userDao = userDao ?? UserDao();

  final StatusDao _statusDao;
  final UserDao _userDao;

  Future<int> addStatus(StatusModel status) => _statusDao.insert(status);

  Future<List<StatusItem>> getActiveStatuses() async {
    final statuses = await _statusDao.getActive();
    final items = <StatusItem>[];
    for (final s in statuses) {
      final user = await _userDao.getById(s.userId);
      items.add(StatusItem(
        status: s,
        userName: user?.name ?? 'Unknown',
        avatarPath: user?.avatarPath,
      ));
    }
    return items;
  }

  Future<void> delete(int id) => _statusDao.delete(id);
}
