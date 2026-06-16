import '../database/app_database.dart';
import '../models/attachment_model.dart';

class AttachmentDao {
  final _store = AppDatabase.instance.store;

  Future<int> insert(AttachmentModel attachment) async {
    await AppDatabase.instance.initialize();
    return _store.insert('attachments', attachment.toMap());
  }

  Future<AttachmentModel?> getByMessageId(int messageId) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query('attachments', where: (r) => r['message_id'] == messageId);
    if (rows.isEmpty) return null;
    return AttachmentModel.fromMap(rows.first);
  }

  Future<List<AttachmentModel>> getAllByMessageId(int messageId) async {
    await AppDatabase.instance.initialize();
    final rows = _store.query('attachments', where: (r) => r['message_id'] == messageId);
    return rows.map(AttachmentModel.fromMap).toList();
  }
}
