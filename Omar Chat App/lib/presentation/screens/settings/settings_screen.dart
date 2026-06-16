import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../state/settings_cubit.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settings)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Notifications'),
                subtitle: const Text('Show notifications for new messages'),
                value: state.notificationsEnabled,
                onChanged: (v) => context.read<SettingsCubit>().setNotifications(v),
              ),
              SwitchListTile(
                title: const Text('Sound alerts'),
                subtitle: const Text('Play a sound when you receive a message'),
                value: state.soundEnabled,
                onChanged: (v) => context.read<SettingsCubit>().setSound(v),
              ),
              SwitchListTile(
                title: const Text('Text-to-Speech'),
                subtitle: const Text('Announce sender name on new messages (e.g. "Ahmed sent you a message")'),
                value: state.ttsEnabled,
                onChanged: (v) => context.read<SettingsCubit>().setTts(v),
              ),
              const ListTile(
                title: Text('About'),
                subtitle: Text('OMAR Chat v1.0.0 — CEN306 Project'),
              ),
            ],
          );
        },
      ),
    );
  }
}
