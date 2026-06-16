import '../../data/repositories/settings_repository.dart';

class UnreadCounterUseCase {
  UnreadCounterUseCase({SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository ?? SettingsRepository();

  final SettingsRepository _settingsRepository;

  Future<void> reset(int chatId, int userId, {int? lastMessageId}) =>
      _settingsRepository.resetUnread(chatId, userId, lastMessageId: lastMessageId);

  Future<int> getTotal(int userId) => _settingsRepository.getTotalUnread(userId);

  Future<int> getForChat(int chatId, int userId) =>
      _settingsRepository.getUnreadCount(chatId, userId);
}
