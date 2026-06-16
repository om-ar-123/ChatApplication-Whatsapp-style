import '../../domain/entities/user.dart';
import '../dao/user_dao.dart';
import '../models/user_model.dart';

class UserRepository {
  UserRepository({UserDao? userDao}) : _userDao = userDao ?? UserDao();

  final UserDao _userDao;

  User _toEntity(UserModel m) => User(
        id: m.id!,
        name: m.name,
        email: m.email,
        jobTitle: m.jobTitle,
        avatarPath: m.avatarPath,
        bio: m.bio,
        isOnline: m.isOnline,
      );

  Future<User?> getById(int id) async {
    final model = await _userDao.getById(id);
    return model == null ? null : _toEntity(model);
  }

  Future<List<User>> getAll() async {
    final models = await _userDao.getAll();
    return models.where((m) => m.id != null).map(_toEntity).toList();
  }

  Future<List<User>> searchByName(String query) async {
    final models = await _userDao.searchByName(query);
    return models.where((m) => m.id != null).map(_toEntity).toList();
  }

  Future<int> insert(UserModel user) => _userDao.insert(user);

  Future<void> update(UserModel user) => _userDao.update(user);

  Future<UserModel?> getModelById(int id) => _userDao.getById(id);
}
