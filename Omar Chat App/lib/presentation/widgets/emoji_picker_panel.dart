import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class EmojiPickerPanel extends StatelessWidget {
  const EmojiPickerPanel({
    super.key,
    required this.onEmojiSelected,
    this.onBackspace,
  });

  final ValueChanged<String> onEmojiSelected;
  final VoidCallback? onBackspace;

  static const _categories = <String, List<String>>{
    'Smileys': [
      '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
      '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙',
      '🥲', '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫',
      '🤔', '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬',
      '😮', '😯', '😲', '😳', '🥺', '😢', '😭', '😤', '😠', '😡',
    ],
    'Gestures': [
      '👍', '👎', '👌', '✌️', '🤞', '🤟', '🤘', '🤙', '👋', '🙌',
      '👏', '🤝', '🙏', '💪', '🫶', '❤️', '🧡', '💛', '💚', '💙',
      '💜', '🖤', '🤍', '💔', '✨', '⭐', '🌟', '💯', '🔥', '💕',
    ],
    'Objects': [
      '📱', '💻', '📷', '🎵', '🎶', '🎉', '🎊', '🎁', '🏆', '⚽',
      '🏀', '🎯', '🎮', '🕹️', '📚', '✏️', '📝', '💼', '📎', '📌',
      '🔔', '🔕', '💬', '💭', '🗨️', '✅', '❌', '❓', '❗', '💡',
    ],
    'Food': [
      '☕', '🍵', '🧃', '🥤', '🍕', '🍔', '🍟', '🌭', '🍿', '🧁',
      '🍰', '🎂', '🍩', '🍪', '🍫', '🍬', '🍭', '🍎', '🍉', '🍇',
      '🥑', '🌮', '🍜', '🍣', '🍱', '🥗', '🍳', '🧀', '🥐', '🍞',
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 320,
          child: DefaultTabController(
            length: _categories.length,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TabBar(
                  isScrollable: true,
                  labelColor: AppColors.appBar,
                  unselectedLabelColor: AppColors.mutedIcon,
                  indicatorColor: AppColors.appBarLight,
                  tabs: _categories.keys.map((name) => Tab(text: name)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: _categories.values.map((emojis) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                        itemCount: emojis.length,
                        itemBuilder: (context, index) {
                          final emoji = emojis[index];
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onEmojiSelected(emoji),
                              borderRadius: BorderRadius.circular(8),
                              child: Center(
                                child: Text(emoji, style: const TextStyle(fontSize: 26)),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
                if (onBackspace != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12, bottom: 8),
                      child: IconButton(
                        onPressed: onBackspace,
                        icon: const Icon(Icons.backspace_outlined),
                        tooltip: 'Delete',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
