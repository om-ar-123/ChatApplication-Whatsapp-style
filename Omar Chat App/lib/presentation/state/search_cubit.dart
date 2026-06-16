import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/message.dart';
import '../../domain/usecases/search_messages_usecase.dart';

class SearchState extends Equatable {
  final List<SearchResult> userResults;
  final List<Message> messageResults;
  final bool isLoading;
  final String query;
  final bool hasSearched;

  const SearchState({
    this.userResults = const [],
    this.messageResults = const [],
    this.isLoading = false,
    this.query = '',
    this.hasSearched = false,
  });

  SearchState copyWith({
    List<SearchResult>? userResults,
    List<Message>? messageResults,
    bool? isLoading,
    String? query,
    bool? hasSearched,
  }) =>
      SearchState(
        userResults: userResults ?? this.userResults,
        messageResults: messageResults ?? this.messageResults,
        isLoading: isLoading ?? this.isLoading,
        query: query ?? this.query,
        hasSearched: hasSearched ?? this.hasSearched,
      );

  @override
  List<Object?> get props => [userResults, messageResults, isLoading, query, hasSearched];
}

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({SearchMessagesUseCase? searchUseCase, this.chatId})
      : _searchUseCase = searchUseCase ?? SearchMessagesUseCase(),
        super(const SearchState());

  final SearchMessagesUseCase _searchUseCase;
  final int? chatId;

  Future<void> loadUsers() async {
    if (chatId != null) return;
    emit(state.copyWith(isLoading: true));
    final users = await _searchUseCase.searchUsers('');
    emit(state.copyWith(userResults: users, isLoading: false, hasSearched: false));
  }

  Future<void> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      await loadUsers();
      return;
    }
    emit(state.copyWith(isLoading: true, query: trimmed, hasSearched: true));
    final users = chatId == null ? await _searchUseCase.searchUsers(trimmed) : <SearchResult>[];
    final messages = chatId != null
        ? await _searchUseCase.searchInChat(chatId!, trimmed)
        : await _searchUseCase.searchMessages(trimmed);
    emit(state.copyWith(
      userResults: users,
      messageResults: messages,
      isLoading: false,
    ));
  }
}
