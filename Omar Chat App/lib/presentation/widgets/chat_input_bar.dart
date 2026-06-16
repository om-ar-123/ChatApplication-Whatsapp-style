import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import 'emoji_picker_panel.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.onMic,
    required this.onDraw,
    this.isRecording = false,
    this.enabled = true,
    this.hint = AppStrings.sendMessage,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final VoidCallback onMic;
  final VoidCallback onDraw;
  final bool isRecording;
  final bool enabled;
  final String hint;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _focusNode = FocusNode();
  bool _emojiSheetOpen = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  void _insertEmoji(String emoji) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;
    final newText = text.replaceRange(start, end, emoji);
    widget.controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + emoji.length),
    );
    setState(() {});
  }

  void _deleteLastChar() {
    final text = widget.controller.text;
    if (text.isEmpty) return;
    final selection = widget.controller.selection;
    if (!selection.isCollapsed) {
      final start = selection.start;
      final end = selection.end;
      widget.controller.value = TextEditingValue(
        text: text.replaceRange(start, end, ''),
        selection: TextSelection.collapsed(offset: start),
      );
    } else {
      final pos = selection.baseOffset;
      if (pos <= 0) return;
      widget.controller.value = TextEditingValue(
        text: '${text.substring(0, pos - 1)}${text.substring(pos)}',
        selection: TextSelection.collapsed(offset: pos - 1),
      );
    }
    setState(() {});
  }

  Future<void> _openEmojiPicker() async {
    _focusNode.unfocus();
    setState(() => _emojiSheetOpen = true);

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => EmojiPickerPanel(
        onEmojiSelected: _insertEmoji,
        onBackspace: _deleteLastChar,
      ),
    );

    if (mounted) {
      setState(() => _emojiSheetOpen = false);
      _focusNode.requestFocus();
    }
  }

  void _handleSend() {
    widget.onSend();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (!widget.enabled) {
      return Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.inputBarBg,
        child: SafeArea(
          top: false,
          child: Text(
            'Messaging is disabled while this user is blocked.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      color: AppColors.inputBarBg,
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Material(
              color: _emojiSheetOpen ? AppColors.appBar.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: _openEmojiPicker,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.emoji_emotions_outlined,
                    color: _emojiSheetOpen ? AppColors.appBar : AppColors.mutedIcon,
                    size: 26,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add, color: AppColors.mutedIcon),
                      onPressed: widget.onAttach,
                      tooltip: 'Attach',
                    ),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: widget.hint,
                          hintStyle: const TextStyle(color: AppColors.mutedIcon),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        style: const TextStyle(fontSize: 15),
                        onSubmitted: (_) => _handleSend(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.draw_outlined, color: AppColors.mutedIcon, size: 22),
                      onPressed: widget.onDraw,
                      tooltip: 'Drawing',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: widget.isRecording ? Colors.red : AppColors.appBarLight,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: hasText ? _handleSend : widget.onMic,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    hasText
                        ? Icons.send
                        : (widget.isRecording ? Icons.stop : Icons.mic),
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
