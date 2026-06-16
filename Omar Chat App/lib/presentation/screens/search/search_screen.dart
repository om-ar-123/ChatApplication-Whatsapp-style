import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/db_constants.dart';
import '../../../domain/usecases/create_chat_usecase.dart';
import '../../state/search_cubit.dart';
import '../../widgets/profile_avatar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, this.chatId});

  final int? chatId;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late TabController _tabController;
  final _createChatUseCase = CreateChatUseCase();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchCubit(chatId: widget.chatId)..loadUsers(),
      child: _SearchBody(
        chatId: widget.chatId,
        controller: _controller,
        tabController: _tabController,
        createChatUseCase: _createChatUseCase,
      ),
    );
  }
}

class _SearchBody extends StatelessWidget {
  const _SearchBody({
    required this.chatId,
    required this.controller,
    required this.tabController,
    required this.createChatUseCase,
  });

  final int? chatId;
  final TextEditingController controller;
  final TabController tabController;
  final CreateChatUseCase createChatUseCase;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        title: Text(chatId != null ? 'Search in chat' : AppStrings.search),
        bottom: TabBar(
          controller: tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(text: chatId != null ? 'In chat' : 'Users'),
            const Tab(text: 'Messages'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: controller,
              autofocus: true,
              onChanged: (q) => context.read<SearchCubit>().search(q),
              decoration: InputDecoration(
                hintText: chatId != null ? 'Search messages in this chat...' : 'Search users or messages...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          context.read<SearchCubit>().search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchCubit, SearchState>(
              builder: (context, state) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.appBarLight));
                }
                return TabBarView(
                  controller: tabController,
                  children: [
                    _UserResults(state: state, createChatUseCase: createChatUseCase),
                    _MessageResults(state: state),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserResults extends StatelessWidget {
  const _UserResults({required this.state, required this.createChatUseCase});

  final SearchState state;
  final CreateChatUseCase createChatUseCase;

  @override
  Widget build(BuildContext context) {
    if (!state.hasSearched && state.userResults.isEmpty) {
      return const Center(child: Text('Loading contacts...'));
    }
    if (state.userResults.isEmpty) {
      return Center(
        child: Text(state.hasSearched ? 'No users found for "${state.query}"' : 'No contacts available'),
      );
    }

    return ListView.separated(
      itemCount: state.userResults.length,
      separatorBuilder: (context, i) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final result = state.userResults[index];
        return ListTile(
          leading: ProfileAvatar(name: result.title, radius: 24),
          title: Text(result.title, style: const TextStyle(fontWeight: FontWeight.w500)),
          subtitle: Text(result.subtitle),
          onTap: () async {
            if (result.userId == null) return;
            final newChatId = await createChatUseCase.execute(
              DbConstants.currentUserId,
              result.userId!,
            );
            if (context.mounted) {
              Navigator.pushNamed(
                context,
                AppRoutes.chatDetail,
                arguments: {
                  'chatId': newChatId,
                  'title': result.title,
                  'otherUserId': result.userId,
                },
              );
            }
          },
        );
      },
    );
  }
}

class _MessageResults extends StatelessWidget {
  const _MessageResults({required this.state});

  final SearchState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasSearched) {
      return const Center(child: Text('Type to search messages'));
    }
    if (state.messageResults.isEmpty) {
      return Center(child: Text('No messages found for "${state.query}"'));
    }
    return ListView.builder(
      itemCount: state.messageResults.length,
      itemBuilder: (context, index) {
        final msg = state.messageResults[index];
        return ListTile(
          leading: const Icon(Icons.chat_bubble_outline, color: AppColors.appBar),
          title: Text(msg.content ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text('Chat #${msg.chatId} · ${msg.senderName ?? ''}'),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.chatDetail,
              arguments: {
                'chatId': msg.chatId,
                'title': msg.senderName ?? 'Chat',
              },
            );
          },
        );
      },
    );
  }
}
