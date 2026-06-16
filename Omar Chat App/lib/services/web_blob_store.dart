import 'dart:typed_data';

/// In-memory file store for web where dart:io is unavailable.
class WebBlobStore {
  WebBlobStore._();
  static final WebBlobStore instance = WebBlobStore._();

  final Map<String, Uint8List> _files = {};

  int _counter = 0;

  String store(Uint8List bytes, String fileName) {
    _counter++;
    final key = 'webstore/${_counter}_$fileName';
    _files[key] = bytes;
    return key;
  }

  Uint8List? get(String key) => _files[key];

  bool contains(String key) => _files.containsKey(key);
}
