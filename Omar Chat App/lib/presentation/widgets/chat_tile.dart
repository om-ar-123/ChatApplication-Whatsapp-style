import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/chat.dart';
import 'profile_avatar.dart';
import 'unread_badge.dart';

class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.chat,
    required this.onTap,
  });

  final Chat chat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasUnread = chat.unreadCount > 0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
          ),
          child: Row(
            children: [
              chat.chatType == 'group'
                  ? CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.appBar,
                      child: const Icon(Icons.groups, color: Colors.white, size: 28),
                    )
                  : ProfileAvatar(name: chat.title, imagePath: chat.otherUserAvatar, radius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                              color: AppColors.chatTitle,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          DateTimeUtils.formatChatTime(chat.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: hasUnread ? AppColors.appBarLight : AppColors.timestamp,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (chat.isMuted)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.notifications_off, size: 16, color: AppColors.mutedIcon),
                          ),
                        if (chat.isBlocked)
                          const Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Icon(Icons.block, size: 16, color: AppColors.blockedBadge),
                          ),
                        Expanded(
                          child: Text(
                            chat.lastMessage ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: hasUnread ? AppColors.unreadText : AppColors.chatSubtitle,
                              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: 8),
                          UnreadBadge(count: chat.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
