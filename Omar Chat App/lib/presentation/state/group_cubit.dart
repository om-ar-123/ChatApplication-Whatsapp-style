import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/constants/db_constants.dart';
import '../../domain/entities/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../domain/usecases/create_group_usecase.dart';
import '../../domain/usecases/create_chat_usecase.dart';
import '../../domain/usecases/send_message_usecase.dart';

class GroupState extends Equatable {
  final List<User> allUsers;
  final Set<int> selectedUserIds;
  final String groupName;
  final String broadcastMessage;
  final bool isLoading;
  final String? error;
  final int? createdChatId;

  const GroupState({
    this.allUsers = const [],
    this.selectedUserIds = const {},
    this.groupName = '',
    this.broadcastMessage = '',
    this.isLoading = false,
    this.error,
    this.createdChatId,
  });

  GroupState copyWith({
    List<User>? allUsers,
    Set<int>? selectedUserIds,
    String? groupName,
    String? broadcastMessage,
    bool? isLoading,
    String? error,
    int? createdChatId,
  }) =>
      GroupState(
        allUsers: allUsers ?? this.allUsers,
        selectedUserIds: selectedUserIds ?? this.selectedUserIds,
        groupName: groupName ?? this.groupName,
        broadcastMessage: broadcastMessage ?? this.broadcastMessage,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        createdChatId: createdChatId,
      );

  @override
  List<Object?> get props =>
      [allUsers, selectedUserIds, groupName, broadcastMessage, isLoading, error, createdChatId];
}

class GroupCubit extends Cubit<GroupState> {
  GroupCubit({
    UserRepository? userRepository,
    CreateGroupUseCase? createGroupUseCase,
    CreateChatUseCase? createChatUseCase,
    SendMessageUseCase? sendMessageUseCase,
  })  : _userRepository = userRepository ?? UserRepository(),
        _createGroupUseCase = createGroupUseCase ?? CreateGroupUseCase(),
        _createChatUseCase = createChatUseCase ?? CreateChatUseCase(),
        _sendMessageUseCase = sendMessageUseCase ?? SendMessageUseCase(),
        super(const GroupState());

  final UserRepository _userRepository;
  final CreateGroupUseCase _createGroupUseCase;
  final CreateChatUseCase _createChatUseCase;
  final SendMessageUseCase _sendMessageUseCase;

  Future<void> loadUsers() async {
    emit(state.copyWith(isLoading: true));
    final users = await _userRepository.getAll();
    final filtered = users.where((u) => u.id != DbConstants.currentUserId).toList();
    emit(state.copyWith(allUsers: filtered, isLoading: false));
  }

  void toggleUser(int userId) {
    final selected = Set<int>.from(state.selectedUserIds);
    if (selected.contains(userId)) {
      selected.remove(userId);
    } else {
      selected.add(userId);
    }
    emit(state.copyWith(selectedUserIds: selected));
  }

  void setGroupName(String name) => emit(state.copyWith(groupName: name));

  void setBroadcastMessage(String msg) => emit(state.copyWith(broadcastMessage: msg));

  void resetForNewGroup() => emit(const GroupState());

  void clearCreatedGroup() => emit(state.copyWith(createdChatId: null));

  Future<int?> createGroup({String? groupName}) async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final title = (groupName ?? state.groupName).trim();
      if (title.isEmpty) {
        throw Exception('Enter a group name');
      }
      if (state.selectedUserIds.isEmpty) {
        throw Exception('Select at least one other member for the group');
      }
      final members = [DbConstants.currentUserId, ...state.selectedUserIds].toSet().toList();
      final chatId = await _createGroupUseCase.execute(title, members);
      emit(state.copyWith(isLoading: false, createdChatId: chatId, groupName: title));
      return chatId;
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
      return null;
    }
  }

  Future<void> broadcastToSelected() async {
    if (state.broadcastMessage.trim().isEmpty) return;
    emit(state.copyWith(isLoading: true, error: null));
    try {
      for (final userId in state.selectedUserIds) {
        final chatId = await _createChatUseCase.execute(DbConstants.currentUserId, userId);
        await _sendMessageUseCase.execute(
          chatId: chatId,
          senderId: DbConstants.currentUserId,
          content: state.broadcastMessage.trim(),
          senderName: 'OMAR',
          notify: false,
        );
      }
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }
}
