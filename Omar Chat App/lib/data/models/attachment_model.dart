class AttachmentModel {
  final int? id;
  final int messageId;
  final String? fileName;
  final String? filePath;
  final String? fileType;
  final int? fileSize;

  const AttachmentModel({
    this.id,
    required this.messageId,
    this.fileName,
    this.filePath,
    this.fileType,
    this.fileSize,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'message_id': messageId,
        'file_name': fileName,
        'file_path': filePath,
        'file_type': fileType,
        'file_size': fileSize,
      };

  factory AttachmentModel.fromMap(Map<String, dynamic> map) => AttachmentModel(
        id: map['id'] as int?,
        messageId: map['message_id'] as int,
        fileName: map['file_name'] as String?,
        filePath: map['file_path'] as String?,
        fileType: map['file_type'] as String?,
        fileSize: map['file_size'] as int?,
      );
}
