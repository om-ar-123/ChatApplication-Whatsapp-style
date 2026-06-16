import '../../data/repositories/chat_repository.dart';

class CreateChatUseCase {
  CreateChatUseCase({ChatRepository? chatRepository})
      : _chatRepository = chatRepository ?? ChatRepository();

  final ChatRepository _chatRepository;

  Future<int> execute(int currentUserId, int otherUserId) =>
      _chatRepository.createDirectChat(currentUserId, otherUserId);
}
