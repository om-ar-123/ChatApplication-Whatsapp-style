import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/db_constants.dart';
import '../../../domain/entities/message.dart';
import '../../../domain/usecases/block_user_usecase.dart';
import '../../../domain/usecases/mute_chat_usecase.dart';
import '../../state/chat_detail_cubit.dart';
import '../../state/chat_list_cubit.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/drawing_board_widget.dart';
import '../../widgets/theme_picker_widget.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/chat_wallpaper.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/date_separator.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/mention_picker.dart';
import '../../../domain/entities/user.dart';
import '../call/call_screen.dart';
import '../../../domain/entities/call_session.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.otherUserId,
    this.isGroupChat = false,
  });

  final int chatId;
  final String title;
  final int? otherUserId;
  final bool isGroupChat;

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _showDrawing = false;
  late final ChatDetailCubit _cubit;
  List<User> _groupMembers = [];
  String _mentionQuery = '';
  bool _showMentionPicker = false;

  final _blockUseCase = BlockUserUseCase();
  final _muteUseCase = MuteChatUseCase();

  @override
  void initState() {
    super.initState();
    _cubit = ChatDetailCubit(
      chatId: widget.chatId,
      otherUserId: widget.otherUserId,
      isGroupChat: widget.isGroupChat,
    )..load();
    _controller.addListener(_onTextChanged);
    if (widget.isGroupChat) _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    final members = await _cubit.getGroupMembers();
    if (mounted) setState(() => _groupMembers = members);
  }

  void _onTextChanged() {
    if (!widget.isGroupChat) return;
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    if (cursor < 0) return;

    final beforeCursor = text.substring(0, cursor);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex >= 0) {
      final query = beforeCursor.substring(atIndex + 1);
      if (!query.contains(' ') && !query.contains('\n')) {
        setState(() {
          _mentionQuery = query;
          _showMentionPicker = true;
        });
        return;
      }
    }
    if (_showMentionPicker) {
      setState(() {
        _showMentionPicker = false;
        _mentionQuery = '';
      });
    }
  }

  void _insertMention(User user) {
    final text = _controller.text;
    final cursor = _controller.selection.baseOffset;
    final beforeCursor = text.substring(0, cursor);
    final atIndex = beforeCursor.lastIndexOf('@');
    if (atIndex < 0) return;

    final newText = '${text.substring(0, atIndex)}@${user.name} ${text.substring(cursor)}';
    final newCursor = atIndex + user.name.length + 2;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
    setState(() {
      _showMentionPicker = false;
      _mentionQuery = '';
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color? _backgroundColor(ChatDetailState state) {
    if (state.themeName == 'lion') return const Color(0xFFD4A574);
    if (state.themeName == 'sea') return const Color(0xFF87CEEB);
    return null;
  }

  List<Widget> _buildMessageList(List<Message> messages) {
    final items = <Widget>[];
    String? lastDateLabel;

    for (final msg in messages) {
      final label = DateSeparator.labelFor(msg.createdAt);
      if (label.isNotEmpty && label != lastDateLabel) {
        items.add(DateSeparator(label: label));
        lastDateLabel = label;
      }
      items.add(
        MessageBubble(
          message: msg,
          isGroupChat: widget.isGroupChat,
          onLongPress: () => _showMessageOptions(context, msg),
        ),
      );
    }
    return items;
  }

  void _showMessageOptions(BuildContext context, Message message) {
    final cubit = _cubit;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.appBar),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  cubit.setReplyTarget(message);
                },
              ),
              if (cubit.canEdit(message))
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.appBar),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    _controller.text = message.content ?? '';
                    cubit.setEditTarget(message);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.blockedBadge),
                title: const Text('Delete for me'),
                onTap: () {
                  Navigator.pop(context);
                  cubit.deleteMessage(message.id, forAll: false);
                },
              ),
              if (cubit.canDeleteForAll(message))
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: AppColors.blockedBadge),
                  title: const Text('Delete for all'),
                  onTap: () {
                    Navigator.pop(context);
                    cubit.deleteMessage(message.id, forAll: true);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatDetailState state) {
    return AppBar(
      backgroundColor: AppColors.appBar,
      foregroundColor: Colors.white,
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: [
          ProfileAvatar(name: widget.title, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (state.isMuted) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.notifications_off, size: 16),
                    ],
                  ],
                ),
                Text(
                  widget.isGroupChat ? 'Group · tap for info' : 'online',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          onPressed: () => openSimulatedCall(
            context,
            contactName: widget.title,
            type: CallType.video,
            isGroup: widget.isGroupChat,
            chatId: widget.chatId,
            contactUserId: widget.otherUserId,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () => openSimulatedCall(
            context,
            contactName: widget.title,
            type: CallType.voice,
            isGroup: widget.isGroupChat,
            chatId: widget.chatId,
            contactUserId: widget.otherUserId,
          ),
        ),
        PopupMenuButton<String>(
          iconColor: Colors.white,
          onSelected: (value) async {
            switch (value) {
              case 'theme':
                showDialog(
                  context: context,
                  builder: (_) => ThemePickerWidget(
                    chatId: widget.chatId,
                    onThemeSelected: () => _cubit.load(),
                  ),
                );
                break;
              case 'mute':
                if (state.isMuted) {
                  await _muteUseCase.unmute(widget.chatId);
                } else {
                  await _muteUseCase.mute(widget.chatId);
                }
                _cubit.load();
                break;
              case 'block':
                if (widget.otherUserId != null) {
                  if (state.isBlocked) {
                    final confirm = await ConfirmDialog.show(
                      context,
                      title: 'Unblock user',
                      message: 'Unblock ${widget.title}? You will be able to send and receive messages again.',
                      confirmLabel: 'Unblock',
                    );
                    if (confirm == true) {
                      await _blockUseCase.unblock(
                        DbConstants.currentUserId,
                        widget.otherUserId!,
                      );
                      _cubit.load();
                      if (context.mounted) {
                        context.read<ChatListCubit>().loadChats();
                      }
                    }
                  } else {
                    final confirm = await ConfirmDialog.show(
                      context,
                      title: 'Block user',
                      message: 'Block ${widget.title}? Only this user will be blocked — other contacts are not affected.',
                      confirmLabel: 'Block',
                    );
                    if (confirm == true) {
                      await _blockUseCase.execute(
                        DbConstants.currentUserId,
                        widget.otherUserId!,
                      );
                      _cubit.load();
                      if (context.mounted) {
                        context.read<ChatListCubit>().loadChats();
                      }
                    }
                  }
                }
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'theme', child: Text('Chat theme')),
            PopupMenuItem(value: 'mute', child: Text(state.isMuted ? 'Unmute' : 'Mute')),
            if (widget.otherUserId != null)
              PopupMenuItem(
                value: 'block',
                child: Text(state.isBlocked ? 'Unblock user' : 'Block user'),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildReplyBar(ChatDetailState state) {
    return Container(
      color: const Color(0xFFF0F2F5),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      child: Row(
        children: [
          Container(width: 4, height: 40, color: AppColors.replyBar),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.replyTarget!.senderName ?? 'Reply',
                  style: const TextStyle(
                    color: AppColors.replyBar,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  state.replyTarget!.content ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.chatSubtitle, fontSize: 13),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.mutedIcon),
            onPressed: () => _cubit.clearReply(),
          ),
        ],
      ),
    );
  }

  void _showAttachOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: AppColors.appBar),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _cubit.attachImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: AppColors.appBar),
              title: const Text('Document'),
              onTap: () {
                Navigator.pop(context);
                _cubit.attachFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chatId <= 0) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('Chat not found')),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          context.read<ChatListCubit>().loadChats();
        }
      },
      child: BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ChatDetailCubit, ChatDetailState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
          if (!state.isLoading && state.messages.isNotEmpty) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Scaffold(
                backgroundColor: AppColors.chatBackground,
                appBar: _buildAppBar(state),
                body: Column(
                  children: [
                    if (state.isBlocked && widget.otherUserId != null)
                      Container(
                        width: double.infinity,
                        color: const Color(0xFFFFEBEE),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Text(
                          'You blocked ${widget.title}. Unblock from the menu to message again.',
                          style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                        ),
                      ),
                    if (state.replyTarget != null) _buildReplyBar(state),
                    if (state.editTarget != null)
                      Container(
                        color: const Color(0xFFFFF3CD),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: 18, color: AppColors.chatSubtitle),
                            const SizedBox(width: 8),
                            const Expanded(child: Text('Editing message')),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _controller.clear();
                                _cubit.clearEdit();
                              },
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ChatWallpaper(
                        backgroundColor: _backgroundColor(state),
                        child: state.isLoading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.appBarLight))
                            : ListView(
                                controller: _scrollController,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                children: _buildMessageList(state.messages),
                              ),
                      ),
                    ),
                    ChatInputBar(
                      controller: _controller,
                      isRecording: state.isRecording,
                      enabled: !state.isBlocked,
                      onSend: () {
                        _cubit.sendText(_controller.text, senderName: 'OMAR');
                        _controller.clear();
                        setState(() {
                          _showMentionPicker = false;
                          _mentionQuery = '';
                        });
                      },
                      onAttach: _showAttachOptions,
                      onMic: () {
                        if (state.isRecording) {
                          _cubit.stopVoiceRecording();
                        } else {
                          _cubit.startVoiceRecording();
                        }
                      },
                      onDraw: () => setState(() => _showDrawing = true),
                    ),
                    if (_showMentionPicker && widget.isGroupChat)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                        child: MentionPicker(
                          members: _groupMembers,
                          query: _mentionQuery,
                          onSelect: _insertMention,
                        ),
                      ),
                  ],
                ),
              ),
              if (_showDrawing)
                DrawingBoardWidget(
                  onSave: (bytes) => _cubit.saveDrawing(bytes),
                  onClose: () => setState(() => _showDrawing = false),
                ),
            ],
          );
        },
      ),
    ),
    );
  }
}
