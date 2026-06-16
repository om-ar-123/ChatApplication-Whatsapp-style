import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'file_storage.dart';
import 'web_blob_store.dart';

class UploadDownloadService {
  UploadDownloadService();

  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> pickImage() async {
    try {
      if (kIsWeb) {
        return await _pickImageWeb();
      }
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file == null) return null;
      return copyToAppDir(file.path, p.basename(file.path));
    } catch (e) {
      debugPrint('pickImage error: $e');
      return null;
    }
  }

  Future<String?> _pickImageWeb() async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        final bytes = await file.readAsBytes();
        final name = file.name.isNotEmpty ? file.name : 'photo.jpg';
        return WebBlobStore.instance.store(bytes, name);
      }
    } catch (e) {
      debugPrint('image_picker web failed: $e');
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
        allowMultiple: false,
      );
      if (result == null || result.files.isEmpty) return null;
      final picked = result.files.single;
      if (picked.bytes != null) {
        return WebBlobStore.instance.store(
          Uint8List.fromList(picked.bytes!),
          picked.name.isNotEmpty ? picked.name : 'photo.jpg',
        );
      }
    } catch (e) {
      debugPrint('file_picker image web failed: $e');
    }
    return null;
  }

  Future<String?> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: kIsWeb);
      if (result == null || result.files.isEmpty) return null;
      final picked = result.files.single;

      if (kIsWeb) {
        if (picked.bytes != null) {
          return WebBlobStore.instance.store(
            Uint8List.fromList(picked.bytes!),
            picked.name,
          );
        }
        return picked.path;
      }

      if (picked.path == null) return null;
      return copyToAppDir(picked.path!, picked.name);
    } catch (e) {
      debugPrint('pickFile error: $e');
      return null;
    }
  }

  Future<String> saveBytes(List<int> bytes, String fileName) {
    return saveBytesToAppDir(bytes, fileName);
  }

  Future<bool> fileExists(String path) => pathExists(path);
}
