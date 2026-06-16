import 'dart:typed_data';
import 'web_blob_store.dart';

Future<String> copyToAppDir(String sourcePath, String fileName) async => sourcePath;

Future<String> saveBytesToAppDir(List<int> bytes, String fileName) async {
  return WebBlobStore.instance.store(Uint8List.fromList(bytes), fileName);
}

Future<bool> pathExists(String path) async {
  return path.startsWith('webstore/') ||
      path.startsWith('blob:') ||
      path.startsWith('http');
}
