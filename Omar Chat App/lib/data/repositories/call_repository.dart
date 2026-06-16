import '../../domain/entities/call_record.dart';
import '../dao/call_dao.dart';
import '../models/call_record_model.dart';

class CallRepository {
  CallRepository({CallDao? callDao}) : _callDao = callDao ?? CallDao();

  final CallDao _callDao;

  CallRecord _toEntity(CallRecordModel m) => CallRecord(
        id: m.id!,
        contactName: m.contactName,
        contactUserId: m.contactUserId,
        chatId: m.chatId,
        callType: m.callType,
        isGroup: m.isGroup,
        isOutgoing: m.isOutgoing,
        durationSeconds: m.durationSeconds,
        createdAt: m.createdAt,
        isMissed: m.isMissed,
      );

  Future<int> save(CallRecordModel record) => _callDao.insert(record);

  Future<List<CallRecord>> getAll() async {
    final models = await _callDao.getAll();
    return models.where((m) => m.id != null).map(_toEntity).toList();
  }
}
