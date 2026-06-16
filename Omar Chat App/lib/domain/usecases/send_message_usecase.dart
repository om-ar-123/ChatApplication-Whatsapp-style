import '../../core/utils/date_time_utils.dart';
import '../../data/models/message_model.dart';
import '../../data/models/chat_model.dart';import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/dao/group_dao.dart';

class SendMessageUseCase {
  SendMessageUseCase({
    MessageRepository? messageRepository,
    ChatRepository? chatRepository,
    SettingsRepository? settingsRepository,
    GroupDao? groupDao,
  })  : _messageRepository = messageRepository ?? MessageRepository(),
        _chatRepository = chatRepository ?? ChatRepository(),
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _groupDao = groupDao ?? GroupDao();

  final MessageRepository _messageRepository;
  final ChatRepository _chatRepository;
  final SettingsRepository _settingsRepository;
  final GroupDao _groupDao;

  Future<int> execute({
    required int chatId,
    required int senderId,
    required String content,
    String messageType = MessageModel.typeText,
    int? replyToMessageId,
    String? senderName,
    bool notify = true,
  }) async {
    final chat = await _chatRepository.getChatById(chatId);
    final members = await _groupDao.getMemberUserIds(chatId);

    // Block check applies to direct chats only — blocking one user must not block group messaging.
    if (chat?.chatType == ChatModel.typeDirect) {
      for (final memberId in members) {
        if (memberId == senderId) continue;
        if (await _settingsRepository.isBlocked(senderId, memberId)) {
          throw Exception('Cannot send message: this user is blocked');
        }
      }
    }

    final now = DateTimeUtils.nowIso();
    final messageId = await _messageRepository.insert(MessageModel(
      chatId: chatId,
      senderId: senderId,
      content: content,
      messageType: messageType,
      replyToMessageId: replyToMessageId,
      createdAt: now,
    ));

    await _chatRepository.updateLastMessage(chatId, _preview(content, messageType));

    for (final memberId in members) {
      if (memberId != senderId) {
        await _settingsRepository.incrementUnread(chatId, memberId);
      }
    }
    return messageId;
  }

  String _preview(String content, String type) {
    switch (type) {
      case MessageModel.typeVoice:
        return '🎤 Voice message';
      case MessageModel.typeFile:
        return '📎 Attachment';
      case MessageModel.typeImage:
      case MessageModel.typeDrawing:
        return '🖼 Image';
      default:
        return content;
    }
  }
}
