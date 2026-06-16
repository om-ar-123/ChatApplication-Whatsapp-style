class CallRecordModel {
  const CallRecordModel({
    this.id,
    required this.contactName,
    required this.callType,
    required this.isOutgoing,
    required this.durationSeconds,
    required this.createdAt,
    this.contactUserId,
    this.chatId,
    this.isGroup = false,
    this.isMissed = false,
  });

  final int? id;
  final String contactName;
  final int? contactUserId;
  final int? chatId;
  final String callType;
  final bool isGroup;
  final bool isOutgoing;
  final int durationSeconds;
  final String createdAt;
  final bool isMissed;

  Map<String, dynamic> toMap() => {
        'id': id,
        'contact_name': contactName,
        'contact_user_id': contactUserId,
        'chat_id': chatId,
        'call_type': callType,
        'is_group': isGroup ? 1 : 0,
        'is_outgoing': isOutgoing ? 1 : 0,
        'duration_seconds': durationSeconds,
        'created_at': createdAt,
        'is_missed': isMissed ? 1 : 0,
      };

  factory CallRecordModel.fromMap(Map<String, dynamic> map) => CallRecordModel(
        id: map['id'] as int?,
        contactName: map['contact_name'] as String? ?? 'Unknown',
        contactUserId: map['contact_user_id'] as int?,
        chatId: map['chat_id'] as int?,
        callType: map['call_type'] as String? ?? 'voice',
        isGroup: (map['is_group'] as int? ?? 0) == 1,
        isOutgoing: (map['is_outgoing'] as int? ?? 1) == 1,
        durationSeconds: map['duration_seconds'] as int? ?? 0,
        createdAt: map['created_at'] as String? ?? '',
        isMissed: (map['is_missed'] as int? ?? 0) == 1,
      );
}
