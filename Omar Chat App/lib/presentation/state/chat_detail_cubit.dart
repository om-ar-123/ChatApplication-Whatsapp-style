import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/db_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/message.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/chat_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/attachment_repository.dart';
import '../../data/models/message_model.dart';
import '../../data/models/attachment_model.dart';
import '../../domain/usecases/send_message_usecase.dart';
import '../../domain/usecases/receive_message_usecase.dart';
import '../../domain/usecases/edit_message_usecase.dart';
import '../../domain/usecases/delete_message_usecase.dart';
import '../../domain/usecases/unread_counter_usecase.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/dao/group_dao.dart';
import '../../domain/entities/user.dart';
import '../../services/media_service.dart';
import '../../services/upload_download_service.dart';

class ChatDetailState extends Equatable {
  final List<Message> messages;
  final Message? replyTarget;
  final Message? editTarget;
  final String? backgroundPath;
  final String? themeName;
  final bool isBlocked;
  final bool isMuted;
  final bool isLoading;
  final bool isRecording;
  final String? error;

  const ChatDetailState({
    this.messages = const [],
    this.replyTarget,
    this.editTarget,
    this.backgroundPath,
    this.themeName,
    this.isBlocked = false,
    this.isMuted = false,
    this.isLoading = false,
    this.isRecording = false,
    this.error,
  });

  ChatDetailState copyWith({
    List<Message>? messages,
    Message? replyTarget,
    Message? editTarget,
    bool clearReply = false,
    bool clearEdit = false,
    String? backgroundPath,
    String? themeName,
    bool? isBlocked,
    bool? isMuted,
    bool? isLoading,
    bool? isRecording,
    String? error,
  }) =>
      ChatDetailState(
        messages: messages ?? this.messages,
        replyTarget: clearReply ? null : (replyTarget ?? this.replyTarget),
        editTarget: clearEdit ? null : (editTarget ?? this.editTarget),
        backgroundPath: backgroundPath ?? this.backgroundPath,
        themeName: themeName ?? this.themeName,
        isBlocked: isBlocked ?? this.isBlocked,
        isMuted: isMuted ?? this.isMuted,
        isLoading: isLoading ?? this.isLoading,
        isRecording: isRecording ?? this.isRecording,
        error: error,
      );

  @override
  List<Object?> get props =>
      [messages, replyTarget, editTarget, backgroundPath, themeName, isBlocked, isMuted, isLoading, isRecording, error];
}

class ChatDetailCubit extends Cubit<ChatDetailState> {
  ChatDetailCubit({
    required this.chatId,
    this.otherUserId,
    this.isGroupChat = false,
    MessageRepository? messageRepository,
    ChatRepository? chatRepository,
    SettingsRepository? settingsRepository,
    AttachmentRepository? attachmentRepository,
    SendMessageUseCase? sendMessageUseCase,
    ReceiveMessageUseCase? receiveMessageUseCase,
    EditMessageUseCase? editMessageUseCase,
    DeleteMessageUseCase? deleteMessageUseCase,
    UnreadCounterUseCase? unreadCounterUseCase,
    UserRepository? userRepository,
    GroupDao? groupDao,
    MediaService? mediaService,
    UploadDownloadService? fileService,
  })  : _messageRepository = messageRepository ?? MessageRepository(),
        _chatRepository = chatRepository ?? ChatRepository(),
        _settingsRepository = settingsRepository ?? SettingsRepository(),
        _attachmentRepository = attachmentRepository ?? AttachmentRepository(),
        _sendMessageUseCase = sendMessageUseCase ?? SendMessageUseCase(),
        _receiveMessageUseCase = receiveMessageUseCase ?? ReceiveMessageUseCase(),
        _editMessageUseCase = editMessageUseCase ?? EditMessageUseCase(),
        _deleteMessageUseCase = deleteMessageUseCase ?? DeleteMessageUseCase(),
        _unreadCounterUseCase = unreadCounterUseCase ?? UnreadCounterUseCase(),
        _userRepository = userRepository ?? UserRepository(),
        _groupDao = groupDao ?? GroupDao(),
        _mediaService = mediaService ?? MediaService(),
        _fileService = fileService ?? UploadDownloadService(),
        super(const ChatDetailState());

  final int chatId;
  final int? otherUserId;
  final bool isGroupChat;
  final MessageRepository _messageRepository;
  final ChatRepository _chatRepository;
  final SettingsRepository _settingsRepository;
  final AttachmentRepository _attachmentRepository;
  final SendMessageUseCase _sendMessageUseCase;
  final ReceiveMessageUseCase _receiveMessageUseCase;
  final EditMessageUseCase _editMessageUseCase;
  final DeleteMessageUseCase _deleteMessageUseCase;
  final UnreadCounterUseCase _unreadCounterUseCase;
  final UserRepository _userRepository;
  final GroupDao _groupDao;
  final MediaService _mediaService;
  final UploadDownloadService _fileService;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final messages = await _messageRepository.getByChatId(chatId);
      final theme = await _settingsRepository.getChatTheme(chatId);
      var blocked = false;
      if (otherUserId != null) {
        blocked = await _settingsRepository.isBlocked(DbConstants.currentUserId, otherUserId!);
      }
      final muted = await _settingsRepository.isMuted(chatId);
      if (messages.isNotEmpty) {
        await _unreadCounterUseCase.reset(
          chatId,
          DbConstants.currentUserId,
          lastMessageId: messages.last.id,
        );
      }
      emit(state.copyWith(
        messages: messages,
        backgroundPath: theme?.backgroundPath,
        themeName: theme?.themeName,
        isMuted: muted,
        isBlocked: blocked,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  void setReplyTarget(Message message) => emit(state.copyWith(replyTarget: message, clearEdit: true));

  void setEditTarget(Message message) => emit(state.copyWith(editTarget: message, clearReply: true));

  void clearReply() => emit(state.copyWith(clearReply: true));

  void clearEdit() => emit(state.copyWith(clearEdit: true));

  Future<List<User>> getGroupMembers() async {
    if (!isGroupChat) return [];
    final members = await _groupDao.getMembers(chatId);
    final users = <User>[];
    for (final member in members) {
      if (member.userId == DbConstants.currentUserId) continue;
      final user = await _userRepository.getById(member.userId);
      if (user != null) users.add(user);
    }
    return users;
  }

  Future<void> sendText(String text, {String? senderName}) async {
    if (text.trim().isEmpty) return;
    final trimmed = text.trim();
    try {
      if (state.editTarget != null) {
        await _editMessageUseCase.execute(
          messageId: state.editTarget!.id,
          senderId: DbConstants.currentUserId,
          newContent: trimmed,
        );
        emit(state.copyWith(clearEdit: true));
      } else {
        await _sendMessageUseCase.execute(
          chatId: chatId,
          senderId: DbConstants.currentUserId,
          content: trimmed,
          replyToMessageId: state.replyTarget?.id,
          senderName: senderName ?? 'OMAR',
        );
        emit(state.copyWith(clearReply: true));
        await load();

        if (!isGroupChat && otherUserId != null) {
          await Future.delayed(const Duration(seconds: 2));
          await _receiveMessageUseCase.simulateDirectReply(
            chatId: chatId,
            otherUserId: otherUserId!,
            userMessage: trimmed,
          );
        } else if (isGroupChat && trimmed.contains('@')) {
          await _receiveMessageUseCase.simulateGroupMentionReplies(
            chatId: chatId,
            userMessage: trimmed,
          );
        }
      }
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> deleteMessage(int messageId, {required bool forAll}) async {
    try {
      await _deleteMessageUseCase.execute(
        messageId: messageId,
        userId: DbConstants.currentUserId,
        forAll: forAll,
      );
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> attachFile() async {
    try {
      final path = await _fileService.pickFile();
      if (path == null) return;
      final fileName = p.basename(path);
      final msgId = await _sendMessageUseCase.execute(
        chatId: chatId,
        senderId: DbConstants.currentUserId,
        content: fileName,
        messageType: MessageModel.typeFile,
        senderName: 'OMAR',
      );
      await _attachmentRepository.save(AttachmentModel(
        messageId: msgId,
        fileName: fileName,
        filePath: path,
        fileType: 'file',
      ));
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> attachImage() async {
    try {
      final path = await _fileService.pickImage();
      if (path == null) return;
      final fileName = p.basename(path);
      final msgId = await _sendMessageUseCase.execute(
        chatId: chatId,
        senderId: DbConstants.currentUserId,
        content: 'Image',
        messageType: MessageModel.typeImage,
        senderName: 'OMAR',
      );
      await _attachmentRepository.save(AttachmentModel(
        messageId: msgId,
        fileName: fileName,
        filePath: path,
        fileType: 'image',
      ));
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> startVoiceRecording() async {
    final ok = await _mediaService.startRecording();
    emit(state.copyWith(isRecording: ok));
  }

  Future<void> stopVoiceRecording() async {
    final path = await _mediaService.stopRecording();
    emit(state.copyWith(isRecording: false));
    if (path == null) return;
    try {
      final msgId = await _sendMessageUseCase.execute(
        chatId: chatId,
        senderId: DbConstants.currentUserId,
        content: path,
        messageType: MessageModel.typeVoice,
        senderName: 'OMAR',
      );
      await _attachmentRepository.save(AttachmentModel(
        messageId: msgId,
        filePath: path,
        fileType: 'voice',
      ));
      await load();

      if (!isGroupChat && otherUserId != null) {
        await Future.delayed(const Duration(seconds: 2));
        await _receiveMessageUseCase.simulateDirectReply(
          chatId: chatId,
          otherUserId: otherUserId!,
          userMessage: '[Voice message]',
          userMessageType: MessageModel.typeVoice,
        );
        await load();
      } else if (isGroupChat) {
        final members = await getGroupMembers();
        if (members.isNotEmpty) {
          await Future.delayed(const Duration(seconds: 2));
          await _receiveMessageUseCase.simulateDirectReply(
            chatId: chatId,
            otherUserId: members.first.id,
            userMessage: '[Voice message]',
            userMessageType: MessageModel.typeVoice,
          );
          await load();
        }
      }
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> saveDrawing(List<int> bytes) async {
    try {
      final path = await _fileService.saveBytes(bytes, 'drawing_${DateTime.now().millisecondsSinceEpoch}.png');
      final msgId = await _sendMessageUseCase.execute(
        chatId: chatId,
        senderId: DbConstants.currentUserId,
        content: 'Drawing',
        messageType: MessageModel.typeDrawing,
        senderName: 'OMAR',
      );
      await _attachmentRepository.save(AttachmentModel(
        messageId: msgId,
        filePath: path,
        fileType: 'drawing',
      ));
      await load();
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  bool canEdit(Message message) =>
      message.senderId == DbConstants.currentUserId &&
      DateTimeUtils.canEditMessage(message.createdAt);

  bool canDeleteForAll(Message message) =>
      message.senderId == DbConstants.currentUserId &&
      DateTimeUtils.canDeleteForAll(message.createdAt);
}
