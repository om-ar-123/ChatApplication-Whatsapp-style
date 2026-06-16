import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/db_constants.dart';
import '../../../core/constants/app_assets.dart';
import '../../../data/models/user_model.dart';
import '../../../domain/entities/user.dart';
import '../../state/profile_cubit.dart';
import '../../widgets/profile_avatar.dart';
import '../../../services/upload_download_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _jobController = TextEditingController();
  final _bioController = TextEditingController();
  String? _avatarPath;
  final _fileService = UploadDownloadService();

  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _jobController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _fillFields(User user) {
    _nameController.text = user.name;
    _emailController.text = user.email ?? '';
    _jobController.text = user.jobTitle ?? '';
    _bioController.text = user.bio ?? '';
    _avatarPath = user.avatarPath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.user != null && _nameController.text.isEmpty) {
            _fillFields(state.user!);
          }
          if (state.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile saved')),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = state.user;
          if (user == null) return const Center(child: Text('User not found'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () async {
                    final path = await _fileService.pickImage();
                    if (path != null) setState(() => _avatarPath = path);
                  },
                  child: ProfileAvatar(name: user.name, imagePath: _avatarPath, radius: 50),
                ),
                const SizedBox(height: 8),
                const Text('Tap avatar to change photo'),
                TextButton.icon(
                  onPressed: () => setState(() => _avatarPath = AppAssets.assetPath(AppAssets.mountainLandscape)),
                  icon: const Icon(Icons.landscape),
                  label: const Text('Use default landscape photo'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _jobController,
                  decoration: const InputDecoration(labelText: 'Job Title'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bioController,
                  decoration: const InputDecoration(labelText: 'Bio'),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.read<ProfileCubit>().update(UserModel(
                            id: DbConstants.currentUserId,
                            name: _nameController.text.trim(),
                            email: _emailController.text.trim(),
                            jobTitle: _jobController.text.trim(),
                            bio: _bioController.text.trim(),
                            avatarPath: _avatarPath,
                            isOnline: true,
                          ));
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
