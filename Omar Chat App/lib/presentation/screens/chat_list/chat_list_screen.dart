import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/navigation/app_route_observer.dart';
import '../../../core/utils/route_args.dart';
import '../../state/chat_list_cubit.dart';
import '../../widgets/chat_tile.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with RouteAware {
  @override
  void initState() {
    super.initState();
    context.read<ChatListCubit>().loadChats();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    context.read<ChatListCubit>().loadChats(showLoading: false);
  }

  Future<void> _openCreateGroup() async {
    final result = await Navigator.pushNamed(context, AppRoutes.createGroup);
    if (!mounted) return;

    await context.read<ChatListCubit>().loadChats(showLoading: false);

    final args = routeArgs(result);
    final chatId = routeInt(args, 'chatId');
    if (chatId == null) return;

    await Navigator.pushNamed(
      context,
      AppRoutes.chatDetail,
      arguments: args,
    );
    if (mounted) {
      await context.read<ChatListCubit>().loadChats(showLoading: false);
    }
  }

  Future<void> _openChat(Map<String, dynamic> arguments) async {
    await Navigator.pushNamed(context, AppRoutes.chatDetail, arguments: arguments);
    if (mounted) {
      await context.read<ChatListCubit>().loadChats(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          AppStrings.appName,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.callHistory),
          ),
          IconButton(
            icon: const Icon(Icons.camera_alt_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.status),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
          ),
          PopupMenuButton<String>(
            iconColor: Colors.white,
            onSelected: (value) {
              switch (value) {
                case 'group':
                  _openCreateGroup();
                  break;
                case 'calls':
                  Navigator.pushNamed(context, AppRoutes.callHistory);
                  break;
                case 'status':
                  Navigator.pushNamed(context, AppRoutes.status);
                  break;
                case 'settings':
                  Navigator.pushNamed(context, AppRoutes.settings);
                  break;
                case 'profile':
                  Navigator.pushNamed(context, AppRoutes.profile);
                  break;
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'group', child: Text('New group')),
              PopupMenuItem(value: 'calls', child: Text('Call history')),
              PopupMenuItem(value: 'status', child: Text('Status')),
              PopupMenuItem(value: 'profile', child: Text('My profile')),
              PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ChatListCubit, ChatListState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.chats.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppColors.appBarLight));
          }

          return Column(
            children: [
              if (state.totalUnread > 0)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFFE7FCE3),
                  child: Row(
                    children: [
                      const Icon(Icons.mark_chat_unread_outlined, size: 18, color: AppColors.appBar),
                      const SizedBox(width: 8),
                      Text(
                        '${state.totalUnread} unread message${state.totalUnread == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: AppColors.chatTitle,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: state.chats.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(AppStrings.noChats, style: TextStyle(color: Colors.grey.shade600)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.appBarLight,
                        onRefresh: () => context.read<ChatListCubit>().refresh(),
                        child: ListView.builder(
                          itemCount: state.chats.length,
                          itemBuilder: (context, index) {
                            final chat = state.chats[index];
                            return ChatTile(
                              chat: chat,
                              onTap: () => _openChat({
                                'chatId': chat.id,
                                'title': chat.title,
                                'otherUserId': chat.otherUserId,
                                'isGroup': chat.chatType == 'group',
                              }),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'new_group_fab',
            backgroundColor: Colors.white,
            foregroundColor: AppColors.appBar,
            elevation: 2,
            onPressed: _openCreateGroup,
            icon: const Icon(Icons.group_add),
            label: const Text(AppStrings.newGroup),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'new_chat_fab',
            backgroundColor: AppColors.appBarLight,
            onPressed: () => Navigator.pushNamed(context, AppRoutes.search),
            child: const Icon(Icons.chat, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
