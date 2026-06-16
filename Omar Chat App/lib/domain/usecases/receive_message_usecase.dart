import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/db_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/models/attachment_model.dart';
import '../../data/dao/group_dao.dart';
import '../../services/auto_reply_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/notification_sound_service.dart';
import '../../services/speech_service.dart';
import '../../services/media_service.dart';

class ReceiveMessageUseCase {
  ReceiveMessageUseCase({
    MessageRepository? messageRepository,
    ChatRepository? chatRepository,
    SettingsRepository? settingsRepository,
    UserRepository? userRepository,
    GroupDao? groupDao,
    AutoReplyService? autoReplyService,
    LocalNotificationService? notificationService,
    NotificationSoundService? soundService,
    SpeechService? speechService,
    AttachmentRepository? attachmentRepository,
    MediaService? mediaService,
  })  : _messageRepository = messageRepository ?? MessageRepository(),
        _chatRepository = chatRepository ?? ChatRepository(),
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _userRepository = userRepository ?? UserRepository(),
        _groupDao = groupDao ?? GroupDao(),
        _autoReplyService = autoReplyService ?? AutoReplyService(),
        _notificationService = notificationService ?? LocalNotificationService(),
        _soundService = soundService ?? NotificationSoundService(),
        _speechService = speechService ?? SpeechService(),
        _attachmentRepository = attachmentRepository ?? AttachmentRepository(),
        _mediaService = mediaService ?? MediaService();

  final MessageRepository _messageRepository;
  final ChatRepository _chatRepository;
  final SettingsRepository _settingsRepository;
  final UserRepository _userRepository;
  final GroupDao _groupDao;
  final AutoReplyService _autoReplyService;
  final LocalNotificationService _notificationService;
  final NotificationSoundService _soundService;
  final SpeechService _speechService;
  final AttachmentRepository _attachmentRepository;
  final MediaService _mediaService;

  /// Simulates another user replying in a direct chat after OMAR sends a message.
  Future<void> simulateDirectReply({
    required int chatId,
    required int otherUserId,
    required String userMessage,
    String userMessageType = MessageModel.typeText,
  }) async {
    final otherUser = await _userRepository.getById(otherUserId);
    if (otherUser == null) return;

    if (await _settingsRepository.isBlocked(DbConstants.currentUserId, otherUserId) ||
        await _settingsRepository.isBlocked(otherUserId, DbConstants.currentUserId)) {
      return;
    }

    final replyWithVoice = userMessageType == MessageModel.typeVoice;
    final reply = _autoReplyService.generateReply(
      userMessage,
      senderName: otherUser.name,
      messageType: replyWithVoice ? MessageModel.typeVoice : MessageModel.typeText,
    );

    if (replyWithVoice) {
      final voicePath = await _mediaService.demoVoiceReplyPath();
      final messageId = await _insertAndNotify(
        chatId: chatId,
        senderId: otherUserId,
        senderName: otherUser.name,
        content: reply,
        messageType: MessageModel.typeVoice,
        recipientId: DbConstants.currentUserId,
      );
      await _attachmentRepository.save(AttachmentModel(
        messageId: messageId,
        filePath: voicePath,
        fileType: 'voice',
      ));
      return;
    }

    await _insertAndNotify(
      chatId: chatId,
      senderId: otherUserId,
      senderName: otherUser.name,
      content: reply,
      recipientId: DbConstants.currentUserId,
    );
  }

  /// Simulates mentioned group members replying after OMAR @mentions them.
  Future<void> simulateGroupMentionReplies({
    required int chatId,
    required String userMessage,
    String userMessageType = MessageModel.typeText,
  }) async {
    final mentionedIds = await getMentionedUserIds(userMessage, chatId);
    if (mentionedIds.isEmpty) return;

    var delaySeconds = 2;
    for (final userId in mentionedIds) {
      if (userId == DbConstants.currentUserId) continue;

      final user = await _userRepository.getById(userId);
      if (user == null) continue;

      if (await _settingsRepository.isBlocked(DbConstants.currentUserId, userId) ||
          await _settingsRepository.isBlocked(userId, DbConstants.currentUserId)) {
        continue;
      }

      await Future.delayed(Duration(seconds: delaySeconds));
      delaySeconds += 2;

      final reply = _autoReplyService.generateReply(
        userMessage,
        senderName: user.name,
        mentionedName: user.name,
        messageType: userMessageType == MessageModel.typeVoice ? MessageModel.typeVoice : MessageModel.typeText,
      );

      if (userMessageType == MessageModel.typeVoice) {
        final voicePath = await _mediaService.demoVoiceReplyPath();
        final messageId = await _insertAndNotify(
          chatId: chatId,
          senderId: userId,
          senderName: user.name,
          content: reply,
          messageType: MessageModel.typeVoice,
          recipientId: DbConstants.currentUserId,
        );
        await _attachmentRepository.save(AttachmentModel(
          messageId: messageId,
          filePath: voicePath,
          fileType: 'voice',
        ));
        continue;
      }

      await _insertAndNotify(
        chatId: chatId,
        senderId: userId,
        senderName: user.name,
        content: reply,
        recipientId: DbConstants.currentUserId,
      );
    }
  }

  /// Inserts an incoming message and notifies the current user.
  Future<int> receiveMessage({
    required int chatId,
    required int senderId,
    required String content,
    String messageType = MessageModel.typeText,
    String? senderName,
    int? recipientId,
  }) {
    return _insertAndNotify(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      content: content,
      messageType: messageType,
      recipientId: recipientId ?? DbConstants.currentUserId,
    );
  }

  Future<int> _insertAndNotify({
    required int chatId,
    required int senderId,
    required String content,
    String messageType = MessageModel.typeText,
    String? senderName,
    required int recipientId,
  }) async {
    final now = DateTimeUtils.nowIso();
    final messageId = await _messageRepository.insert(MessageModel(
      chatId: chatId,
      senderId: senderId,
      content: content,
      messageType: messageType,
      createdAt: now,
    ));

    await _chatRepository.updateLastMessage(chatId, _preview(content, messageType));
    await _settingsRepository.incrementUnread(chatId, recipientId);

    if (recipientId == DbConstants.currentUserId) {
      await _notifyCurrentUser(
        messageId: messageId,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        messageType: messageType,
      );
    }

    return messageId;
  }

  Future<void> _notifyCurrentUser({
    required int messageId,
    required int chatId,
    required int senderId,
    String? senderName,
    required String content,
    required String messageType,
  }) async {
    if (!(await _areNotificationsEnabled())) return;
    if (await _settingsRepository.isMuted(chatId)) return;

    final name = senderName ?? (await _userRepository.getById(senderId))?.name ?? 'Someone';
    final body = _preview(content, messageType);
    final mentionedIds = await getMentionedUserIds(content, chatId);
    final mentioned = mentionedIds.contains(DbConstants.currentUserId);

    try {
      await _soundService.playMessageSound();

      if (!kIsWeb) {
        if (mentioned) {
          final chat = await _chatRepository.getChatById(chatId);
          final groupName = chat?.title ?? 'a group';
          await _notificationService.showMentionNotification(
            id: messageId,
            senderName: name,
            groupName: groupName,
            body: body,
          );
        } else {
          await _notificationService.showMessageNotification(
            id: messageId,
            senderName: name,
            body: body,
          );
        }
      }

      if (mentioned) {
        final chat = await _chatRepository.getChatById(chatId);
        final groupName = chat?.title ?? 'a group';
        await _speechService.speakMention(name, groupName);
      } else {
        await _speechService.speakMessageReceived(name);
      }
    } catch (e) {
      debugPrint('Notify skipped: $e');
    }
  }

  Future<bool> _areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('notifications_enabled') ?? true;
  }

  Future<List<int>> getMentionedUserIds(String content, int chatId) async {
    final members = await _groupDao.getMembers(chatId);
    final mentioned = <int>[];
    for (final member in members) {
      final user = await _userRepository.getById(member.userId);
      if (user != null && content.contains('@${user.name}')) {
        mentioned.add(user.id);
      }
    }
    return mentioned;
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
