import '../database/app_database.dart';
import '../models/call_record_model.dart';

class CallDao {
  final _store = AppDatabase.instance.store;

  Future<int> insert(CallRecordModel record) async {
    await AppDatabase.instance.initialize();
    return _store.insert('call_history', record.toMap());
  }

  Future<List<CallRecordModel>> getAll() async {
    await AppDatabase.instance.initialize();
    final rows = _store.query(
      'call_history',
      compare: (a, b) =>
          (b['created_at'] as String? ?? '').compareTo(a['created_at'] as String? ?? ''),
    );
    return rows.map(CallRecordModel.fromMap).toList();
  }

  Future<void> deleteAll() async {
    await AppDatabase.instance.initialize();
    await _store.deleteWhere('call_history', test: (_) => true);
  }
}
