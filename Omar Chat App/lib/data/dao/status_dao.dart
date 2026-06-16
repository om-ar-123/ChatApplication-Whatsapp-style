import '../database/app_database.dart';
import '../models/status_model.dart';
import '../../core/utils/date_time_utils.dart';

class StatusDao {
  final _store = AppDatabase.instance.store;

  Future<int> insert(StatusModel status) async {
    await AppDatabase.instance.initialize();
    return _store.insert('statuses', status.toMap());
  }

  Future<List<StatusModel>> getActive() async {
    await AppDatabase.instance.initialize();
    final now = DateTimeUtils.nowIso();
    final rows = _store.query(
      'statuses',
      where: (r) {
        final exp = r['expires_at'] as String?;
        return exp == null || exp.compareTo(now) > 0;
      },
      compare: (a, b) => (b['created_at'] as String? ?? '').compareTo(a['created_at'] as String? ?? ''),
    );
    return rows.map(StatusModel.fromMap).toList();
  }

  Future<List<StatusModel>> getByUserId(int userId) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query(
      'statuses',
      where: (r) => r['user_id'] == userId,
      compare: (a, b) => (b['created_at'] as String? ?? '').compareTo(a['created_at'] as String? ?? ''),
    );
    return rows.map(StatusModel.fromMap).toList();
  }

  Future<void> delete(int id) async {
    await AppDatabase.instance.initialize();
    await _store.deleteWhere('statuses', test: (r) => r['id'] == id);
  }
}
