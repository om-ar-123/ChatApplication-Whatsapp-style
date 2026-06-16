class CallRecord {
  const CallRecord({
    required this.id,
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

  final int id;
  final String contactName;
  final int? contactUserId;
  final int? chatId;
  final String callType;
  final bool isGroup;
  final bool isOutgoing;
  final int durationSeconds;
  final String createdAt;
  final bool isMissed;

  bool get isVideo => callType == 'video';
  bool get isVoice => callType == 'voice';
}
