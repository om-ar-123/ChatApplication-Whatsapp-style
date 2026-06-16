import 'package:flutter/material.dart';
import '../../data/repositories/settings_repository.dart';

class ThemePickerWidget extends StatelessWidget {
  ThemePickerWidget({super.key, required this.chatId, this.onThemeSelected});

  final int chatId;
  final VoidCallback? onThemeSelected;
  final SettingsRepository _settings = SettingsRepository();

  static const themes = [
    ('default', null, Color(0xFFECE5DD)),
    ('lion', 'assets/images/lion.png', Color(0xFFD4A574)),
    ('sea', 'assets/images/sea.png', Color(0xFF87CEEB)),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chat Theme'),
      content: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: themes.map((t) {
          return GestureDetector(
            onTap: () async {
              await _settings.setChatTheme(chatId, t.$1, backgroundPath: t.$2);
              if (context.mounted) Navigator.pop(context);
              onThemeSelected?.call();
            },
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: t.$3,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: t.$2 != null ? const Icon(Icons.image) : null,
                ),
                const SizedBox(height: 4),
                Text(t.$1),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
