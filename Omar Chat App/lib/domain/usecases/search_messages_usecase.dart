import '../../domain/entities/message.dart';
import '../../core/constants/db_constants.dart';
import '../../data/repositories/message_repository.dart';
import '../../data/repositories/user_repository.dart';

class SearchResult {
  final Message? message;
  final int? chatId;
  final int? userId;
  final String title;
  final String subtitle;

  SearchResult({
    this.message,
    this.chatId,
    this.userId,
    required this.title,
    required this.subtitle,
  });
}

class SearchMessagesUseCase {
  SearchMessagesUseCase({
    MessageRepository? messageRepository,
    UserRepository? userRepository,
  })  : _messageRepository = messageRepository ?? MessageRepository(),
        _userRepository = userRepository ?? UserRepository();

  final MessageRepository _messageRepository;
  final UserRepository _userRepository;

  Future<List<Message>> searchMessages(String query) =>
      _messageRepository.searchGlobal(query);

  Future<List<Message>> searchInChat(int chatId, String query) =>
      _messageRepository.searchInChat(chatId, query);

  Future<List<SearchResult>> searchUsers(String query) async {
    final users = await _userRepository.searchByName(query);
    return users
        .where((u) => u.id != DbConstants.currentUserId)
        .map((u) => SearchResult(
              userId: u.id,
              title: u.name,
              subtitle: u.email ?? u.jobTitle ?? '',
            ))
        .toList();
  }
}
