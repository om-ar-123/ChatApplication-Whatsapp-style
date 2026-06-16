import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/message_repository.dart';

class DeleteMessageUseCase {
  DeleteMessageUseCase({MessageRepository? messageRepository})
      : _messageRepository = messageRepository ?? MessageRepository();

  final MessageRepository _messageRepository;

  Future<void> execute({
    required int messageId,
    required int userId,
    required bool forAll,
  }) async {
    final message = await _messageRepository.getModelById(messageId);
    if (message == null) throw Exception('Message not found');

    if (forAll) {
      if (message.senderId != userId) {
        throw Exception('Only sender can delete for all');
      }
      if (!DateTimeUtils.canDeleteForAll(message.createdAt)) {
        throw Exception('Delete for all expired (5 minutes)');
      }
      await _messageRepository.update(message.copyWith(
        isDeleted: true,
        isForAll: true,
        deletedAt: DateTimeUtils.nowIso(),
      ));
    } else {
      await _messageRepository.update(message.copyWith(
        isDeleted: true,
        isForAll: false,
        deletedAt: DateTimeUtils.nowIso(),
      ));
    }
  }
}
