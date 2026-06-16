import '../../data/repositories/settings_repository.dart';

class MuteChatUseCase {
  MuteChatUseCase({SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository ?? SettingsRepository();

  final SettingsRepository _settingsRepository;

  Future<void> mute(int chatId, {DateTime? until}) =>
      _settingsRepository.muteChat(chatId, until: until);

  Future<void> unmute(int chatId) => _settingsRepository.unmuteChat(chatId);

  Future<bool> isMuted(int chatId) => _settingsRepository.isMuted(chatId);
}
