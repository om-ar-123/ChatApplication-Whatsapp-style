import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/db_constants.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../data/models/status_model.dart';
import '../../../data/repositories/status_repository.dart';
import '../../widgets/profile_avatar.dart';
import '../../widgets/media_image.dart';
import '../../../services/upload_download_service.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  final _statusRepo = StatusRepository();
  final _fileService = UploadDownloadService();
  List<StatusItem> _statuses = [];
  bool _loading = true;
  bool _posting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await _statusRepo.getActiveStatuses();
    if (!mounted) return;
    setState(() {
      _statuses = items;
      _loading = false;
    });
  }

  Future<void> _saveStatus({String? mediaPath, String? caption}) async {
    if (_posting) return;
    if (caption == null && mediaPath == null) return;
    if ((caption == null || caption.trim().isEmpty) && mediaPath == null) return;

    setState(() => _posting = true);
    try {
      final now = DateTime.now().toUtc();
      await _statusRepo.addStatus(StatusModel(
        userId: DbConstants.currentUserId,
        mediaPath: mediaPath,
        caption: (caption != null && caption.trim().isNotEmpty) ? caption.trim() : null,
        createdAt: now.toIso8601String(),
        expiresAt: now.add(const Duration(hours: 24)).toIso8601String(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status posted')),
        );
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not post status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _addTextStatus() async {
    final caption = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Text status'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'What is on your mind?'),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: const Text('Post'),
            ),
          ],
        );
      },
    );

    if (caption == null || caption.isEmpty) return;
    await _saveStatus(caption: caption);
  }

  Future<void> _showPhotoComposer(String mediaPath) async {
    final caption = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final controller = TextEditingController();
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Share photo status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: MediaImage(
                  path: mediaPath,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Add a caption (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.appBar),
                      onPressed: () => Navigator.pop(ctx, controller.text.trim()),
                      child: const Text('Share'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (caption == null) return;
    await _saveStatus(mediaPath: mediaPath, caption: caption);
  }

  Future<void> _addPhotoStatus() async {
    final path = await _fileService.pickImage();
    if (!mounted) return;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick image. Try again or use text status.')),
      );
      return;
    }
    await _showPhotoComposer(path);
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.text_fields, color: AppColors.appBar),
              title: const Text('Text status'),
              onTap: () {
                Navigator.pop(sheetCtx);
                _addTextStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_a_photo, color: AppColors.appBar),
              title: const Text('Photo status'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _addPhotoStatus();
              },
            ),
            ListTile(
              leading: const Icon(Icons.landscape, color: AppColors.appBar),
              title: const Text('Default landscape photo'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _showPhotoComposer(AppAssets.assetPath(AppAssets.mountainLandscape));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _viewStatus(StatusItem item) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileAvatar(name: item.userName, radius: 30),
              const SizedBox(height: 8),
              Text(item.userName, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              if (item.status.mediaPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: MediaImage(
                    path: item.status.mediaPath!,
                    height: 220,
                    width: 280,
                    fit: BoxFit.cover,
                  ),
                ),
              if (item.status.caption != null) ...[
                const SizedBox(height: 12),
                Text(item.status.caption!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 8),
              Text(
                DateTimeUtils.formatChatTime(item.status.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBar,
        foregroundColor: Colors.white,
        title: const Text(AppStrings.status),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.appBarLight,
        onPressed: _posting ? null : _showAddOptions,
        child: _posting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.appBarLight))
          : _statuses.isEmpty
              ? const Center(child: Text('No statuses yet. Tap + to add one!'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    itemCount: _statuses.length,
                    itemBuilder: (context, index) {
                      final item = _statuses[index];
                      final hasPhoto = item.status.mediaPath != null;
                      return ListTile(
                        leading: ProfileAvatar(name: item.userName, imagePath: item.avatarPath),
                        title: Text(item.userName),
                        subtitle: Text(
                          item.status.caption ??
                              (hasPhoto
                                  ? '📷 Photo · ${DateTimeUtils.formatChatTime(item.status.createdAt)}'
                                  : DateTimeUtils.formatChatTime(item.status.createdAt)),
                        ),
                        trailing: hasPhoto
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: MediaImage(
                                  path: item.status.mediaPath!,
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.chevron_right),
                        onTap: () => _viewStatus(item),
                      );
                    },
                  ),
                ),
    );
  }
}
