import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/speech_service.dart';
import '../../services/local_notification_service.dart';
import '../../services/notification_sound_service.dart';

class SettingsState extends Equatable {
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool ttsEnabled;
  final bool isLoading;

  const SettingsState({
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.ttsEnabled = true,
    this.isLoading = false,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? ttsEnabled,
    bool? isLoading,
  }) =>
      SettingsState(
        notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
        soundEnabled: soundEnabled ?? this.soundEnabled,
        ttsEnabled: ttsEnabled ?? this.ttsEnabled,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  List<Object?> get props => [notificationsEnabled, soundEnabled, ttsEnabled, isLoading];
}

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    SpeechService? speechService,
    LocalNotificationService? notificationService,
    NotificationSoundService? soundService,
  })  : _speechService = speechService ?? SpeechService(),
        _notificationService = notificationService ?? LocalNotificationService(),
        _soundService = soundService ?? NotificationSoundService(),
        super(const SettingsState());

  final SpeechService _speechService;
  final LocalNotificationService _notificationService;
  final NotificationSoundService _soundService;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true));
    final prefs = await SharedPreferences.getInstance();
    final tts = await _speechService.isEnabled();
    final sound = await _soundService.isEnabled();
    emit(state.copyWith(
      notificationsEnabled: prefs.getBool('notifications_enabled') ?? true,
      soundEnabled: sound,
      ttsEnabled: tts,
      isLoading: false,
    ));
  }

  Future<void> setNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    if (enabled) await _notificationService.init();
    emit(state.copyWith(notificationsEnabled: enabled));
  }

  Future<void> setSound(bool enabled) async {
    await _soundService.setEnabled(enabled);
    if (enabled) await _soundService.init();
    emit(state.copyWith(soundEnabled: enabled));
  }

  Future<void> setTts(bool enabled) async {
    await _speechService.setEnabled(enabled);
    emit(state.copyWith(ttsEnabled: enabled));
  }
}
