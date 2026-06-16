import '../database/app_database.dart';
import '../models/user_model.dart';

class UserDao {
  final _store = AppDatabase.instance.store;

  Future<int> insert(UserModel user) async {
    await AppDatabase.instance.initialize();
    return _store.insert('users', user.toMap());
  }

  Future<int> update(UserModel user) async {
    await AppDatabase.instance.initialize();
    return _store.update('users', user.toMap(), id: user.id!);
  }

  Future<UserModel?> getById(int id) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query('users', where: (r) => r['id'] == id);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<List<UserModel>> getAll() async {
    await AppDatabase.instance.initialize();
    final rows = _store.query('users', compare: (a, b) => (a['name'] as String).compareTo(b['name'] as String));
    return rows.map(UserModel.fromMap).toList();
  }

  Future<List<UserModel>> searchByName(String query) async {
    await AppDatabase.instance.initialize();
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return getAll();

    final rows = _store.query(
      'users',
      where: (r) {
        final name = (r['name'] as String? ?? '').toLowerCase();
        final email = (r['email'] as String? ?? '').toLowerCase();
        final job = (r['job_title'] as String? ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || job.contains(q);
      },
      compare: (a, b) => (a['name'] as String).compareTo(b['name'] as String),
    );
    return rows.map(UserModel.fromMap).toList();
  }

  Future<void> delete(int id) async {
    await AppDatabase.instance.initialize();
    await _store.deleteWhere('users', test: (r) => r['id'] == id);
  }
}
