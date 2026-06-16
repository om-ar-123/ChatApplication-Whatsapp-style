import '../../domain/entities/message.dart';
import '../dao/message_dao.dart';
import '../dao/attachment_dao.dart';
import '../dao/user_dao.dart';
import '../models/message_model.dart';

class MessageRepository {
  MessageRepository({
    MessageDao? messageDao,
    AttachmentDao? attachmentDao,
    UserDao? userDao,
  })  : _messageDao = messageDao ?? MessageDao(),
        _attachmentDao = attachmentDao ?? AttachmentDao(),
        _userDao = userDao ?? UserDao();

  final MessageDao _messageDao;
  final AttachmentDao _attachmentDao;
  final UserDao _userDao;

  Future<Message> _toEntity(MessageModel m) async {
    String? replyPreview;
    if (m.replyToMessageId != null) {
      final reply = await _messageDao.getById(m.replyToMessageId!);
      replyPreview = reply?.content;
    }
    final sender = await _userDao.getById(m.senderId);
    final attachment = m.id != null ? await _attachmentDao.getByMessageId(m.id!) : null;
    return Message(
      id: m.id!,
      chatId: m.chatId,
      senderId: m.senderId,
      content: m.content,
      messageType: m.messageType,
      replyToMessageId: m.replyToMessageId,
      replyPreview: replyPreview,
      isEdited: m.isEdited,
      createdAt: m.createdAt,
      editedAt: m.editedAt,
      isDeleted: m.isDeleted,
      isForAll: m.isForAll,
      senderName: sender?.name,
      attachmentPath: attachment?.filePath,
      attachmentName: attachment?.fileName,
    );
  }

  Future<List<Message>> getByChatId(int chatId) async {
    final models = await _messageDao.getByChatId(chatId);
    final messages = <Message>[];
    for (final m in models) {
      if (m.id == null) continue;
      if (m.isDeleted && m.isForAll) continue;
      messages.add(await _toEntity(m));
    }
    return messages;
  }

  Future<MessageModel?> getModelById(int id) => _messageDao.getById(id);

  Future<int> insert(MessageModel message) => _messageDao.insert(message);

  Future<void> update(MessageModel message) => _messageDao.update(message);

  Future<List<Message>> searchGlobal(String query) async {
    final models = await _messageDao.searchGlobal(query);
    return Future.wait(models.where((m) => m.id != null).map(_toEntity));
  }

  Future<List<Message>> searchInChat(int chatId, String query) async {
    final models = await _messageDao.searchInChat(chatId, query);
    return Future.wait(models.where((m) => m.id != null).map(_toEntity));
  }
}
