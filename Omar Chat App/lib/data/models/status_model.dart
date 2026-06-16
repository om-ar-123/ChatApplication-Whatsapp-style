class StatusModel {
  final int? id;
  final int userId;
  final String? mediaPath;
  final String? caption;
  final String? createdAt;
  final String? expiresAt;

  const StatusModel({
    this.id,
    required this.userId,
    this.mediaPath,
    this.caption,
    this.createdAt,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'media_path': mediaPath,
        'caption': caption,
        'created_at': createdAt,
        'expires_at': expiresAt,
      };

  factory StatusModel.fromMap(Map<String, dynamic> map) => StatusModel(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        mediaPath: map['media_path'] as String?,
        caption: map['caption'] as String?,
        createdAt: map['created_at'] as String?,
        expiresAt: map['expires_at'] as String?,
      );
}
