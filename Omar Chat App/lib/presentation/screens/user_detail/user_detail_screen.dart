import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/db_constants.dart';
import '../../../domain/usecases/block_user_usecase.dart';
import '../../../domain/usecases/create_chat_usecase.dart';
import '../../state/profile_cubit.dart';
import '../../state/chat_list_cubit.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/confirm_dialog.dart';
import '../call/call_screen.dart';
import '../../../domain/entities/call_session.dart';

class UserDetailScreen extends StatefulWidget {
  const UserDetailScreen({super.key, required this.userId});

  final int userId;

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  static final _createChatUseCase = CreateChatUseCase();
  final _blockUseCase = BlockUserUseCase();
  bool _isBlocked = false;
  bool _checkingBlock = true;

  @override
  void initState() {
    super.initState();
    _loadBlockState();
  }

  Future<void> _loadBlockState() async {
    if (widget.userId == DbConstants.currentUserId) {
      setState(() {
        _checkingBlock = false;
        _isBlocked = false;
      });
      return;
    }
    final blocked = await _blockUseCase.isBlocked(DbConstants.currentUserId, widget.userId);
    if (mounted) {
      setState(() {
        _isBlocked = blocked;
        _checkingBlock = false;
      });
    }
  }

  Future<void> _toggleBlock(String userName) async {
    final wasBlocked = _isBlocked;
    if (_isBlocked) {
      final confirm = await ConfirmDialog.show(
        context,
        title: 'Unblock user',
        message: 'Unblock $userName? You can send and receive messages again.',
        confirmLabel: 'Unblock',
      );
      if (confirm != true) return;
      await _blockUseCase.unblock(DbConstants.currentUserId, widget.userId);
    } else {
      final confirm = await ConfirmDialog.show(
        context,
        title: 'Block user',
        message: 'Block $userName only? Other contacts will not be affected.',
        confirmLabel: 'Block',
      );
      if (confirm != true) return;
      await _blockUseCase.execute(DbConstants.currentUserId, widget.userId);
    }
    await _loadBlockState();
    if (mounted) {
      context.read<ChatListCubit>().loadChats();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(wasBlocked ? 'User unblocked' : 'User blocked')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId <= 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Info')),
        body: const Center(child: Text('Invalid user')),
      );
    }

    return BlocProvider(
      create: (_) => ProfileCubit(userId: widget.userId)..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('User Info')),
        body: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final user = state.user;
            if (user == null) return const Center(child: Text('User not found'));

            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  ProfileAvatar(
                    name: user.name,
                    imagePath: user.avatarPath,
                    radius: 50,
                    onTap: () {},
                  ),
                  const SizedBox(height: 16),
                  Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                  if (user.email != null) ...[
                    const SizedBox(height: 8),
                    Text(user.email!, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                  if (user.jobTitle != null) ...[
                    const SizedBox(height: 8),
                    Text(user.jobTitle!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ],
                  if (user.bio != null) ...[
                    const SizedBox(height: 16),
                    Text(user.bio!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: user.isOnline ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(user.isOnline ? 'Online' : 'Offline'),
                    ],
                  ),
                  if (_isBlocked) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'This user is blocked',
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ContactAction(
                        icon: Icons.call,
                        label: 'Call',
                        onTap: () => openSimulatedCall(
                          context,
                          contactName: user.name,
                          type: CallType.voice,
                          contactUserId: user.id,
                        ),
                      ),
                      const SizedBox(width: 32),
                      _ContactAction(
                        icon: Icons.videocam,
                        label: 'Video',
                        onTap: () => openSimulatedCall(
                          context,
                          contactName: user.name,
                          type: CallType.video,
                          contactUserId: user.id,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (widget.userId != DbConstants.currentUserId && !_checkingBlock)
                    OutlinedButton.icon(
                      onPressed: () => _toggleBlock(user.name),
                      icon: Icon(_isBlocked ? Icons.lock_open : Icons.block, color: AppColors.blockedBadge),
                      label: Text(_isBlocked ? 'Unblock user' : 'Block user'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.blockedBadge,
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  if (widget.userId != DbConstants.currentUserId && !_checkingBlock)
                    const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _isBlocked
                        ? null
                        : () async {
                            final chatId = await _createChatUseCase.execute(
                              DbConstants.currentUserId,
                              user.id,
                            );
                            if (context.mounted) {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.chatDetail,
                                arguments: {
                                  'chatId': chatId,
                                  'title': user.name,
                                  'otherUserId': user.id,
                                },
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                    child: const Text('Message'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContactAction extends StatelessWidget {
  const _ContactAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF008069),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
