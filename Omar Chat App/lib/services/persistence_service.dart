import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'file_storage.dart';

/// Saves and loads the in-memory database as JSON so data survives app restarts.
class PersistenceService {
  PersistenceService._();
  static final PersistenceService instance = PersistenceService._();

  static const _prefsKey = 'omar_chat_store_v1';
  static const _fileName = 'omar_chat_store.json';

  Future<void> save(Map<String, dynamic> data) async {
    final json = jsonEncode(data);
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, json);
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    await writeTextFile('${dir.path}/$_fileName', json);
  }

  Future<Map<String, dynamic>?> load() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        final json = prefs.getString(_prefsKey);
        if (json == null || json.isEmpty) return null;
        return jsonDecode(json) as Map<String, dynamic>;
      }
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/$_fileName';
      final json = await readTextFile(path);
      if (json == null || json.isEmpty) return null;
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    await deleteFileIfExists('${dir.path}/$_fileName');
  }
}
