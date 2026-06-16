import '../../core/utils/date_time_utils.dart';
import '../../data/models/call_record_model.dart';
import '../../data/repositories/call_repository.dart';

class SaveCallUseCase {
  SaveCallUseCase({CallRepository? callRepository})
      : _callRepository = callRepository ?? CallRepository();

  final CallRepository _callRepository;

  Future<int> execute({
    required String contactName,
    required String callType,
    required int durationSeconds,
    int? contactUserId,
    int? chatId,
    bool isGroup = false,
    bool isOutgoing = true,
  }) {
    return _callRepository.save(CallRecordModel(
      contactName: contactName,
      contactUserId: contactUserId,
      chatId: chatId,
      callType: callType,
      isGroup: isGroup,
      isOutgoing: isOutgoing,
      durationSeconds: durationSeconds,
      createdAt: DateTimeUtils.nowIso(),
      isMissed: durationSeconds == 0,
    ));
  }
}
