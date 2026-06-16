import '../../data/repositories/settings_repository.dart';

class BlockUserUseCase {
  BlockUserUseCase({SettingsRepository? settingsRepository})
      : _settingsRepository = settingsRepository ?? SettingsRepository();

  final SettingsRepository _settingsRepository;

  Future<void> execute(int blockerId, int blockedId) =>
      _settingsRepository.blockUser(blockerId, blockedId);

  Future<void> unblock(int blockerId, int blockedId) =>
      _settingsRepository.unblockUser(blockerId, blockedId);

  Future<bool> isBlocked(int userId1, int userId2) =>
      _settingsRepository.isBlocked(userId1, userId2);
}
