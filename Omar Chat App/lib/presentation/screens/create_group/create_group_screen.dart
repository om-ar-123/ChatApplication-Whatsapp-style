import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../state/group_cubit.dart';
import '../../widgets/profile_avatar.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _broadcastController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<GroupCubit>().resetForNewGroup();
    context.read<GroupCubit>().loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _broadcastController.dispose();
    super.dispose();
  }

  String? _missingRequirement(GroupState state) {
    final name = _nameController.text.trim();
    if (name.isEmpty) return AppStrings.groupNameHint;
    if (state.selectedUserIds.isEmpty) return AppStrings.selectGroupMembers;
    return null;
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || context.read<GroupCubit>().state.selectedUserIds.isEmpty) return;

    final chatId = await context.read<GroupCubit>().createGroup(groupName: name);
    if (!mounted || chatId == null) return;

    final title = context.read<GroupCubit>().state.groupName;
    context.read<GroupCubit>().clearCreatedGroup();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$title" ${AppStrings.groupCreated.toLowerCase()}')),
    );

    Navigator.pop(context, {
      'chatId': chatId,
      'title': title,
      'isGroup': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.createGroup),
        actions: [
          BlocBuilder<GroupCubit, GroupState>(
            builder: (context, state) {
              final canCreate = _missingRequirement(state) == null && !state.isLoading;
              return TextButton(
                onPressed: canCreate ? _createGroup : null,
                child: Text(
                  'Create',
                  style: TextStyle(
                    color: canCreate ? Colors.white : Colors.white54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: BlocConsumer<GroupCubit, GroupState>(
        listener: (context, state) {
          if (state.error != null) {
            final message = state.error!.replaceFirst('Exception: ', '');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        builder: (context, state) {
          final missing = _missingRequirement(state);
          final canCreate = missing == null && !state.isLoading;
          final selectedUsers = state.allUsers
              .where((user) => state.selectedUserIds.contains(user.id))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Group name',
                    hintText: 'e.g. Project Team, Study Group',
                    prefixIcon: Icon(Icons.groups_outlined),
                  ),
                  onChanged: (value) {
                    context.read<GroupCubit>().setGroupName(value);
                    setState(() {});
                  },
                ),
              ),
              if (selectedUsers.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedUsers.length,
                    separatorBuilder: (_, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final user = selectedUsers[index];
                      return InputChip(
                        avatar: ProfileAvatar(name: user.name, imagePath: user.avatarPath, radius: 12),
                        label: Text(user.name),
                        onDeleted: () {
                          context.read<GroupCubit>().toggleUser(user.id);
                          setState(() {});
                        },
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  '${state.selectedUserIds.length} selected · You are added automatically',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
              if (missing != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    missing,
                    style: const TextStyle(color: AppColors.appBar, fontSize: 13),
                  ),
                ),
              const Divider(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Add members',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
              ),
              Expanded(
                child: state.isLoading && state.allUsers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: state.allUsers.length,
                        itemBuilder: (context, index) {
                          final user = state.allUsers[index];
                          final selected = state.selectedUserIds.contains(user.id);
                          return CheckboxListTile(
                            value: selected,
                            onChanged: (_) {
                              context.read<GroupCubit>().toggleUser(user.id);
                              setState(() {});
                            },
                            secondary: ProfileAvatar(name: user.name, imagePath: user.avatarPath),
                            title: Text(user.name),
                            subtitle: Text(user.jobTitle ?? user.email ?? ''),
                          );
                        },
                      ),
              ),
              ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                title: const Text('Optional: message selected users'),
                subtitle: const Text('Send the same text to direct chats (does not create a group)'),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: TextField(
                      controller: _broadcastController,
                      decoration: const InputDecoration(
                        labelText: 'Broadcast message',
                      ),
                      onChanged: context.read<GroupCubit>().setBroadcastMessage,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: ElevatedButton(
                      onPressed: state.selectedUserIds.isEmpty || state.broadcastMessage.trim().isEmpty
                          ? null
                          : () => context.read<GroupCubit>().broadcastToSelected(),
                      child: const Text('Send to selected users'),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: !canCreate ? null : _createGroup,
                    icon: state.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.group_add),
                    label: Text(state.isLoading ? 'Creating...' : AppStrings.createGroup),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
