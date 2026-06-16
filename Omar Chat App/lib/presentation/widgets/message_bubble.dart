import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/db_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/message.dart';
import '../../data/models/message_model.dart';
import 'voice_message_widget.dart';
import 'attachment_preview.dart';
import 'mention_text.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.onLongPress,
    this.isGroupChat = false,
  });

  final Message message;
  final VoidCallback? onLongPress;
  final bool isGroupChat;

  @override
  Widget build(BuildContext context) {
    final isMe = message.senderId == DbConstants.currentUserId;
    final showSender = isGroupChat && !isMe && message.senderName != null;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    Widget content;
    if (message.isDeleted && message.isForAll) {
      content = _deletedContent();
    } else {
      content = _messageContent(isMe);
    }

    return GestureDetector(
      onLongPress: message.isDeleted && message.isForAll ? null : onLongPress,
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? 64 : 8,
          right: isMe ? 8 : 64,
          top: 2,
          bottom: 2,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (showSender)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 2),
                child: Text(
                  message.senderName!,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _senderColor(message.senderId),
                  ),
                ),
              ),
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                constraints: BoxConstraints(maxWidth: maxWidth),
                decoration: BoxDecoration(
                  color: isMe ? AppColors.bubbleSent : AppColors.bubbleReceived,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(8),
                    topRight: const Radius.circular(8),
                    bottomLeft: Radius.circular(isMe ? 8 : 2),
                    bottomRight: Radius.circular(isMe ? 2 : 8),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: content,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deletedContent() {
    return Text(
      AppStrings.messageDeleted,
      style: TextStyle(
        fontStyle: FontStyle.italic,
        fontSize: 14,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _messageContent(bool isMe) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.replyPreview != null) _replyPreview(isMe),
        if (message.messageType == MessageModel.typeVoice) ...[
          VoiceMessageWidget(
            path: message.attachmentPath ??
                ((message.content?.contains('/') ?? false) || (message.content?.contains('\\') ?? false)
                    ? message.content!
                    : ''),
          ),
          if (message.content != null &&
              message.content!.isNotEmpty &&
              message.content != message.attachmentPath &&
              !(message.content!.contains('/') || message.content!.contains('\\')))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(message.content!, style: const TextStyle(fontSize: 13)),
            ),
        ] else if (message.messageType == MessageModel.typeFile ||
            message.messageType == MessageModel.typeImage ||
            message.messageType == MessageModel.typeDrawing)
          AttachmentPreview(
            path: message.attachmentPath,
            name: message.attachmentName ?? message.content,
            type: message.messageType,
          )
        else
          MentionText(text: message.content ?? ''),
        const SizedBox(height: 2),
        _metaRow(isMe),
      ],
    );
  }

  Widget _replyPreview(bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: isMe ? const Color(0xFFC8E6C0) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
        border: Border(
          left: BorderSide(color: isMe ? AppColors.replyBar : AppColors.appBarLight, width: 4),
        ),
      ),
      child: Text(
        message.replyPreview!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: AppColors.chatSubtitle),
      ),
    );
  }

  Widget _metaRow(bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (message.isEdited) ...[
          const Text(
            AppStrings.edited,
            style: TextStyle(fontSize: 11, color: AppColors.timestamp),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          DateTimeUtils.formatMessageTime(message.createdAt),
          style: const TextStyle(fontSize: 11, color: AppColors.timestamp),
        ),
        if (isMe) ...[
          const SizedBox(width: 3),
          Icon(
            Icons.done_all,
            size: 16,
            color: AppColors.timestamp,
          ),
        ],
      ],
    );
  }

  Color _senderColor(int senderId) {
    const colors = [
      Color(0xFF06CF9C),
      Color(0xFF53BDEB),
      Color(0xFFE542A3),
      Color(0xFFA694FF),
      Color(0xFFFF9500),
      Color(0xFF007AFF),
    ];
    return colors[senderId % colors.length];
  }
}
