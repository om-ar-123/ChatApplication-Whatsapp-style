import 'in_memory_store.dart';

/// Database facade — sqflite on Android/iOS; JSON-backed store on web.
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  final InMemoryStore _store = InMemoryStore.instance;

  InMemoryStore get store => _store;

  Future<void> initialize() => _store.initialize();
}
