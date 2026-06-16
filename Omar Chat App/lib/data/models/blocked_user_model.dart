class BlockedUserModel {
  final int? id;
  final int blockerUserId;
  final int blockedUserId;
  final String? createdAt;

  const BlockedUserModel({
    this.id,
    required this.blockerUserId,
    required this.blockedUserId,
    this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'blocker_user_id': blockerUserId,
        'blocked_user_id': blockedUserId,
        'created_at': createdAt,
      };

  factory BlockedUserModel.fromMap(Map<String, dynamic> map) => BlockedUserModel(
        id: map['id'] as int?,
        blockerUserId: map['blocker_user_id'] as int,
        blockedUserId: map['blocked_user_id'] as int,
        createdAt: map['created_at'] as String?,
      );
}
