import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/db_constants.dart';
import '../../domain/entities/chat.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/usecases/unread_counter_usecase.dart';

class ChatListState extends Equatable {
  final List<Chat> chats;
  final int totalUnread;
  final bool isLoading;
  final String? error;

  const ChatListState({
    this.chats = const [],
    this.totalUnread = 0,
    this.isLoading = false,
    this.error,
  });

  ChatListState copyWith({
    List<Chat>? chats,
    int? totalUnread,
    bool? isLoading,
    String? error,
  }) =>
      ChatListState(
        chats: chats ?? this.chats,
        totalUnread: totalUnread ?? this.totalUnread,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  @override
  List<Object?> get props => [chats, totalUnread, isLoading, error];
}

class ChatListCubit extends Cubit<ChatListState> {
  ChatListCubit({
    ChatRepository? chatRepository,
    UnreadCounterUseCase? unreadCounterUseCase,
  })  : _chatRepository = chatRepository ?? ChatRepository(),
        _unreadCounterUseCase = unreadCounterUseCase ?? UnreadCounterUseCase(),
        super(const ChatListState());

  final ChatRepository _chatRepository;
  final UnreadCounterUseCase _unreadCounterUseCase;

  Future<void> loadChats({bool showLoading = true}) async {
    if (showLoading || state.chats.isEmpty) {
      emit(state.copyWith(isLoading: true, error: null));
    }
    try {
      final chats = await _chatRepository.getChatsForUser(DbConstants.currentUserId);
      final total = await _unreadCounterUseCase.getTotal(DbConstants.currentUserId);
      emit(state.copyWith(chats: chats, totalUnread: total, isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> onChatOpened(int chatId, {int? lastMessageId}) async {
    await _unreadCounterUseCase.reset(
      chatId,
      DbConstants.currentUserId,
      lastMessageId: lastMessageId,
    );
    await loadChats();
  }

  Future<void> refresh() => loadChats();
}
