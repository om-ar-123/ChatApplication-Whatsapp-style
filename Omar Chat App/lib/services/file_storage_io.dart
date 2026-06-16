import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<String> copyToAppDir(String sourcePath, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final dest = File(p.join(dir.path, fileName));
  await File(sourcePath).copy(dest.path);
  return dest.path;
}

Future<String> saveBytesToAppDir(List<int> bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final dest = File(p.join(dir.path, fileName));
  await dest.writeAsBytes(bytes);
  return dest.path;
}

Future<bool> pathExists(String path) async => File(path).exists();

Future<void> writeTextFile(String path, String content) async {
  await File(path).writeAsString(content);
}

Future<String?> readTextFile(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  return file.readAsString();
}

Future<void> deleteFileIfExists(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}
