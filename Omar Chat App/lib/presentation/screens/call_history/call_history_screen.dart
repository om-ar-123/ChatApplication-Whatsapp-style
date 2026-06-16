import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../domain/entities/call_record.dart';
import '../../state/call_history_cubit.dart';
import '../../widgets/profile_avatar.dart';

class CallHistoryScreen extends StatelessWidget {
  const CallHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CallHistoryCubit()..load(),
      child: const _CallHistoryView(),
    );
  }
}

class _CallHistoryView extends StatelessWidget {
  const _CallHistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        title: const Text('Call History'),
      ),
      body: BlocBuilder<CallHistoryCubit, CallHistoryState>(
        builder: (context, state) {
          if (state.isLoading && state.calls.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.appBarLight),
            );
          }

          if (state.calls.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No calls yet',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your voice and video calls will appear here',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.appBarLight,
            onRefresh: () => context.read<CallHistoryCubit>().load(),
            child: ListView.separated(
              itemCount: state.calls.length,
              separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final call = state.calls[index];
                return _CallHistoryTile(call: call);
              },
            ),
          );
        },
      ),
    );
  }
}

class _CallHistoryTile extends StatelessWidget {
  const _CallHistoryTile({required this.call});

  final CallRecord call;

  @override
  Widget build(BuildContext context) {
    final icon = call.isVideo ? Icons.videocam : Icons.call;
    final directionIcon = call.isOutgoing ? Icons.call_made : Icons.call_received;
    final directionColor = call.isMissed
        ? AppColors.blockedBadge
        : call.isOutgoing
            ? AppColors.appBar
            : AppColors.appBarLight;

    return ListTile(
      leading: call.isGroup
          ? CircleAvatar(
              backgroundColor: AppColors.appBar.withValues(alpha: 0.15),
              child: const Icon(Icons.groups, color: AppColors.appBar),
            )
          : ProfileAvatar(name: call.contactName, radius: 24),
      title: Text(
        call.contactName,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: call.isMissed ? AppColors.blockedBadge : AppColors.chatTitle,
        ),
      ),
      subtitle: Row(
        children: [
          Icon(directionIcon, size: 14, color: directionColor),
          const SizedBox(width: 4),
          Text(
            _subtitle(call),
            style: const TextStyle(fontSize: 13, color: AppColors.chatSubtitle),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            DateTimeUtils.formatMessageTime(call.createdAt),
            style: const TextStyle(fontSize: 12, color: AppColors.timestamp),
          ),
          const SizedBox(height: 4),
          Icon(icon, size: 18, color: AppColors.mutedIcon),
        ],
      ),
    );
  }

  String _subtitle(CallRecord call) {
    if (call.isMissed) return 'Missed call';
    if (call.durationSeconds > 0) {
      final m = call.durationSeconds ~/ 60;
      final s = call.durationSeconds % 60;
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return call.isVideo ? 'Video call' : 'Voice call';
  }
}
