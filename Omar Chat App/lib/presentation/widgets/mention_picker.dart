import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/user.dart';
import 'profile_avatar.dart';

class MentionPicker extends StatelessWidget {
  const MentionPicker({
    super.key,
    required this.members,
    required this.query,
    required this.onSelect,
  });

  final List<User> members;
  final String query;
  final ValueChanged<User> onSelect;

  @override
  Widget build(BuildContext context) {
    final filtered = members
        .where((u) => u.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final user = filtered[index];
            return ListTile(
              dense: true,
              leading: ProfileAvatar(name: user.name, radius: 16),
              title: Text(
                user.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              onTap: () => onSelect(user),
            );
          },
        ),
      ),
    );
  }
}
