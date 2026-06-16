import '../dao/attachment_dao.dart';
import '../models/attachment_model.dart';

class AttachmentRepository {
  AttachmentRepository({AttachmentDao? attachmentDao})
      : _attachmentDao = attachmentDao ?? AttachmentDao();

  final AttachmentDao _attachmentDao;

  Future<int> save(AttachmentModel attachment) => _attachmentDao.insert(attachment);

  Future<AttachmentModel?> getByMessageId(int messageId) =>
      _attachmentDao.getByMessageId(messageId);
}
