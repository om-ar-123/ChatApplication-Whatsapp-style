class ThemeSettingModel {
  final int? id;
  final int chatId;
  final String? themeName;
  final String? backgroundPath;

  const ThemeSettingModel({
    this.id,
    required this.chatId,
    this.themeName,
    this.backgroundPath,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'chat_id': chatId,
        'theme_name': themeName,
        'background_path': backgroundPath,
      };

  factory ThemeSettingModel.fromMap(Map<String, dynamic> map) =>
      ThemeSettingModel(
        id: map['id'] as int?,
        chatId: map['chat_id'] as int,
        themeName: map['theme_name'] as String?,
        backgroundPath: map['background_path'] as String?,
      );
}
