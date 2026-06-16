import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/message_repository.dart';

class EditMessageUseCase {
  EditMessageUseCase({MessageRepository? messageRepository})
      : _messageRepository = messageRepository ?? MessageRepository();

  final MessageRepository _messageRepository;

  Future<void> execute({
    required int messageId,
    required int senderId,
    required String newContent,
  }) async {
    final message = await _messageRepository.getModelById(messageId);
    if (message == null) throw Exception('Message not found');
    if (message.senderId != senderId) throw Exception('Only sender can edit');
    if (!DateTimeUtils.canEditMessage(message.createdAt)) {
      throw Exception('Edit window expired (10 minutes)');
    }

    await _messageRepository.update(message.copyWith(
      content: newContent,
      isEdited: true,
      editedAt: DateTimeUtils.nowIso(),
    ));
  }
}
