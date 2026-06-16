import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../core/constants/db_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../services/persistence_service.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/group_model.dart';
import '../models/status_model.dart';

/// App data store — SQLite (sqflite) on mobile/desktop; JSON-backed lists on web.
class InMemoryStore {
  InMemoryStore._();
  static final InMemoryStore instance = InMemoryStore._();

  bool _initialized = false;
  Database? _db;

  final List<Map<String, dynamic>> users = [];
  final List<Map<String, dynamic>> chats = [];
  final List<Map<String, dynamic>> chatMembers = [];
  final List<Map<String, dynamic>> messages = [];
  final List<Map<String, dynamic>> attachments = [];
  final List<Map<String, dynamic>> statuses = [];
  final List<Map<String, dynamic>> themeSettings = [];
  final List<Map<String, dynamic>> blockedUsers = [];
  final List<Map<String, dynamic>> mutedChats = [];
  final List<Map<String, dynamic>> unreadCounts = [];
  final List<Map<String, dynamic>> callHistory = [];

  int _nextId(String table) {
    final list = _table(table);
    if (list.isEmpty) return 1;
    return list.map((r) => r['id'] as int? ?? 0).reduce((a, b) => a > b ? a : b) + 1;
  }

  List<Map<String, dynamic>> _table(String name) {
    switch (name) {
      case 'users':
        return users;
      case 'chats':
        return chats;
      case 'chat_members':
        return chatMembers;
      case 'messages':
        return messages;
      case 'attachments':
        return attachments;
      case 'statuses':
        return statuses;
      case 'theme_settings':
        return themeSettings;
      case 'blocked_users':
        return blockedUsers;
      case 'muted_chats':
        return mutedChats;
      case 'unread_counts':
        return unreadCounts;
      case 'call_history':
        return callHistory;
      default:
        throw ArgumentError('Unknown table: $name');
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) {
      final saved = await PersistenceService.instance.load();
      if (saved != null) {
        _loadFromJson(saved);
      } else {
        _seedAll();
        await _persist();
      }
    } else {
      try {
        await _initSqlite();
      } catch (_) {
        // Desktop or platforms without sqflite native support — JSON fallback.
        final saved = await PersistenceService.instance.load();
        if (saved != null) {
          _loadFromJson(saved);
        } else {
          _seedAll();
          await _persist();
        }
      }
    }
    _initialized = true;
  }

  Future<void> _initSqlite() async {
    final dbPath = p.join(await getDatabasesPath(), DbConstants.dbName);
    _db = await openDatabase(
      dbPath,
      version: DbConstants.dbVersion,
      onCreate: (db, version) async {
        for (final sql in DbConstants.allCreateStatements) {
          await db.execute(sql);
        }
        _seedAll();
        await _syncAllToDb(db);
      },
    );

    final count = Sqflite.firstIntValue(await _db!.rawQuery('SELECT COUNT(*) FROM users')) ?? 0;
    if (count == 0) {
      _seedAll();
      await _syncAllToDb(_db!);
    } else {
      await _loadAllFromDb();
    }
  }

  Future<void> _loadAllFromDb() async {
    users..clear()..addAll(await _readTable('users'));
    chats..clear()..addAll(await _readTable('chats'));
    chatMembers..clear()..addAll(await _readTable('chat_members'));
    messages..clear()..addAll(await _readTable('messages'));
    attachments..clear()..addAll(await _readTable('attachments'));
    statuses..clear()..addAll(await _readTable('statuses'));
    themeSettings..clear()..addAll(await _readTable('theme_settings'));
    blockedUsers..clear()..addAll(await _readTable('blocked_users'));
    mutedChats..clear()..addAll(await _readTable('muted_chats'));
    unreadCounts..clear()..addAll(await _readTable('unread_counts'));
    callHistory..clear()..addAll(await _readTable('call_history'));
  }

  Future<List<Map<String, dynamic>>> _readTable(String table) async {
    final rows = await _db!.query(table);
    return rows.map((r) => Map<String, dynamic>.from(r)).toList();
  }

  Future<void> _syncAllToDb(Database db) async {
    for (final table in [
      'users',
      'chats',
      'chat_members',
      'messages',
      'attachments',
      'statuses',
      'theme_settings',
      'blocked_users',
      'muted_chats',
      'unread_counts',
      'call_history',
    ]) {
      for (final row in _table(table)) {
        await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    }
  }

  Future<void> _writeRow(String table, Map<String, dynamic> row) async {
    if (_db == null) return;
    await _db!.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _updateRow(String table, Map<String, dynamic> values, {required int id}) async {
    if (_db == null) return;
    await _db!.update(table, values, where: 'id = ?', whereArgs: [id]);
  }
  Map<String, dynamic> toJson() => {
        'users': List<Map<String, dynamic>>.from(users),
        'chats': List<Map<String, dynamic>>.from(chats),
        'chat_members': List<Map<String, dynamic>>.from(chatMembers),
        'messages': List<Map<String, dynamic>>.from(messages),
        'attachments': List<Map<String, dynamic>>.from(attachments),
        'statuses': List<Map<String, dynamic>>.from(statuses),
        'theme_settings': List<Map<String, dynamic>>.from(themeSettings),
        'blocked_users': List<Map<String, dynamic>>.from(blockedUsers),
        'muted_chats': List<Map<String, dynamic>>.from(mutedChats),
        'unread_counts': List<Map<String, dynamic>>.from(unreadCounts),
        'call_history': List<Map<String, dynamic>>.from(callHistory),
      };

  void _loadFromJson(Map<String, dynamic> json) {
    users..clear()..addAll(_rows(json, 'users'));
    chats..clear()..addAll(_rows(json, 'chats'));
    chatMembers..clear()..addAll(_rows(json, 'chat_members'));
    messages..clear()..addAll(_rows(json, 'messages'));
    attachments..clear()..addAll(_rows(json, 'attachments'));
    statuses..clear()..addAll(_rows(json, 'statuses'));
    themeSettings..clear()..addAll(_rows(json, 'theme_settings'));
    blockedUsers..clear()..addAll(_rows(json, 'blocked_users'));
    mutedChats..clear()..addAll(_rows(json, 'muted_chats'));
    unreadCounts..clear()..addAll(_rows(json, 'unread_counts'));
    callHistory..clear()..addAll(_rows(json, 'call_history'));
  }

  List<Map<String, dynamic>> _rows(Map<String, dynamic> json, String key) {
    final raw = json[key];
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<void> _persist() => PersistenceService.instance.save(toJson());

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final id = values['id'] as int? ?? _nextId(table);
    final row = Map<String, dynamic>.from(values)..['id'] = id;
    _table(table).add(row);
    if (_db != null) {
      await _writeRow(table, row);
    } else {
      await _persist();
    }
    return id;
  }

  Future<int> update(String table, Map<String, dynamic> values, {required int id}) async {
    final list = _table(table);
    final index = list.indexWhere((r) => r['id'] == id);
    if (index == -1) return 0;
    list[index] = {...list[index], ...values, 'id': id};
    if (_db != null) {
      await _updateRow(table, list[index], id: id);
    } else {
      await _persist();
    }
    return 1;
  }

  Future<int> updateWhere(
    String table,
    Map<String, dynamic> values, {
    required bool Function(Map<String, dynamic>) test,
  }) async {
    var count = 0;
    final list = _table(table);
    for (var i = 0; i < list.length; i++) {
      if (test(list[i])) {
        list[i] = {...list[i], ...values};
        count++;
        if (_db != null) {
          await _updateRow(table, list[i], id: list[i]['id'] as int);
        }
      }
    }
    if (count > 0 && _db == null) await _persist();
    return count;
  }

  Future<void> deleteWhere(String table, {required bool Function(Map<String, dynamic>) test}) async {
    final list = _table(table);
    final toRemove = list.where(test).toList();
    if (toRemove.isEmpty) return;
    if (_db != null) {
      for (final row in toRemove) {
        await _db!.delete(table, where: 'id = ?', whereArgs: [row['id']]);
      }
    }
    list.removeWhere(test);
    if (_db == null) await _persist();
  }

  List<Map<String, dynamic>> query(
    String table, {
    bool Function(Map<String, dynamic>)? where,
    int Function(Map<String, dynamic>, Map<String, dynamic>)? compare,
    bool descending = false,
  }) {
    var result = _table(table).where((r) => where?.call(r) ?? true).toList();
    if (compare != null) {
      result.sort((a, b) => descending ? compare(b, a) : compare(a, b));
    }
    return result;
  }

  void _seedAll() {
    users.clear();
    chats.clear();
    chatMembers.clear();
    messages.clear();
    attachments.clear();
    statuses.clear();
    themeSettings.clear();
    blockedUsers.clear();
    mutedChats.clear();
    unreadCounts.clear();
    callHistory.clear();

    final now = DateTimeUtils.nowIso();
    final hourAgo = DateTime.now().toUtc().subtract(const Duration(hours: 1)).toIso8601String();
    final twoHoursAgo = DateTime.now().toUtc().subtract(const Duration(hours: 2)).toIso8601String();
    final expires = DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String();

    for (final u in [
      UserModel(id: 1, name: 'OMAR', email: 'omar@omarchat.com', jobTitle: 'Software Engineer', bio: 'Building OMAR Chat', isOnline: true),
      UserModel(id: 2, name: 'Mohamed', email: 'mohamed@example.com', jobTitle: 'UI Designer', bio: 'Love clean interfaces', isOnline: true),
      UserModel(id: 3, name: 'Ahmed', email: 'ahmed@example.com', jobTitle: 'Backend Developer', bio: 'Coffee and code', isOnline: false),
      UserModel(id: 4, name: 'Sara', email: 'sara@example.com', jobTitle: 'Business Analyst', bio: 'Data-driven decisions', isOnline: true),
      UserModel(id: 5, name: 'Ali', email: 'ali@example.com', jobTitle: 'Project Manager', bio: 'Keeping the team on track', isOnline: false),
      UserModel(id: 6, name: 'Layla', email: 'layla@example.com', jobTitle: 'QA Engineer', bio: 'Finding bugs so you do not have to', isOnline: true),
      UserModel(id: 7, name: 'Youssef', email: 'youssef@example.com', jobTitle: 'DevOps Engineer', bio: 'Automate everything', isOnline: true),
      UserModel(id: 8, name: 'Nour', email: 'nour@example.com', jobTitle: 'Product Owner', bio: 'User stories and sprint planning', isOnline: false),
    ]) {
      users.add(u.toMap());
    }

    for (final c in [
      ChatModel(id: 1, chatType: ChatModel.typeDirect, title: 'Mohamed', lastMessage: 'Hey OMAR, how are you?', lastMessageTime: now, createdAt: now),
      ChatModel(id: 2, chatType: ChatModel.typeDirect, title: 'Ahmed', lastMessage: 'See you tomorrow!', lastMessageTime: hourAgo, createdAt: hourAgo),
      ChatModel(id: 3, chatType: ChatModel.typeGroup, title: 'Project Team', lastMessage: 'Meeting at 3 PM', lastMessageTime: now, createdAt: now),
      ChatModel(id: 4, chatType: ChatModel.typeDirect, title: 'Layla', lastMessage: 'Can you review my test cases?', lastMessageTime: hourAgo, createdAt: hourAgo),
      ChatModel(id: 5, chatType: ChatModel.typeDirect, title: 'Youssef', lastMessage: 'Deployment is live!', lastMessageTime: twoHoursAgo, createdAt: twoHoursAgo),
      ChatModel(id: 6, chatType: ChatModel.typeGroup, title: 'CEN306 Study Group', lastMessage: 'Who has the report draft?', lastMessageTime: now, createdAt: now),
    ]) {
      chats.add(c.toMap());
    }

    for (final m in [
      ChatMemberModel(id: 1, chatId: 1, userId: 1, role: 'member'),
      ChatMemberModel(id: 2, chatId: 1, userId: 2, role: 'member'),
      ChatMemberModel(id: 3, chatId: 2, userId: 1, role: 'member'),
      ChatMemberModel(id: 4, chatId: 2, userId: 3, role: 'member'),
      ChatMemberModel(id: 5, chatId: 3, userId: 1, role: 'admin'),
      ChatMemberModel(id: 6, chatId: 3, userId: 2, role: 'member'),
      ChatMemberModel(id: 7, chatId: 3, userId: 4, role: 'member'),
      ChatMemberModel(id: 8, chatId: 3, userId: 5, role: 'member'),
      ChatMemberModel(id: 9, chatId: 4, userId: 1, role: 'member'),
      ChatMemberModel(id: 10, chatId: 4, userId: 6, role: 'member'),
      ChatMemberModel(id: 11, chatId: 5, userId: 1, role: 'member'),
      ChatMemberModel(id: 12, chatId: 5, userId: 7, role: 'member'),
      ChatMemberModel(id: 13, chatId: 6, userId: 1, role: 'admin'),
      ChatMemberModel(id: 14, chatId: 6, userId: 3, role: 'member'),
      ChatMemberModel(id: 15, chatId: 6, userId: 6, role: 'member'),
      ChatMemberModel(id: 16, chatId: 6, userId: 8, role: 'member'),
    ]) {
      chatMembers.add(m.toMap());
    }

    for (final msg in [
      MessageModel(id: 1, chatId: 1, senderId: 2, content: 'Hey OMAR, how are you?', createdAt: now),
      MessageModel(id: 2, chatId: 1, senderId: 1, content: 'I am good, thanks!', createdAt: now),
      MessageModel(id: 3, chatId: 2, senderId: 3, content: 'See you tomorrow!', createdAt: hourAgo),
      MessageModel(id: 4, chatId: 3, senderId: 4, content: 'Meeting at 3 PM', createdAt: now),
      MessageModel(id: 5, chatId: 3, senderId: 1, content: 'Got it!', createdAt: now),
      MessageModel(id: 6, chatId: 4, senderId: 6, content: 'Can you review my test cases?', createdAt: hourAgo),
      MessageModel(id: 7, chatId: 5, senderId: 7, content: 'Deployment is live!', createdAt: twoHoursAgo),
      MessageModel(id: 8, chatId: 6, senderId: 8, content: 'Who has the report draft?', createdAt: now),
      MessageModel(id: 9, chatId: 6, senderId: 3, content: 'I am working on the architecture section.', createdAt: now),
    ]) {
      messages.add(msg.toMap());
    }

    for (final row in [
      {'id': 1, 'chat_id': 1, 'user_id': 1, 'unread_count': 1, 'last_read_message_id': 1},
      {'id': 2, 'chat_id': 2, 'user_id': 1, 'unread_count': 1, 'last_read_message_id': 3},
      {'id': 3, 'chat_id': 3, 'user_id': 1, 'unread_count': 2, 'last_read_message_id': 4},
      {'id': 4, 'chat_id': 4, 'user_id': 1, 'unread_count': 1, 'last_read_message_id': 6},
      {'id': 5, 'chat_id': 5, 'user_id': 1, 'unread_count': 1, 'last_read_message_id': 7},
      {'id': 6, 'chat_id': 6, 'user_id': 1, 'unread_count': 2, 'last_read_message_id': 8},
    ]) {
      unreadCounts.add(row);
    }

    final statusNow = DateTime.now().toUtc();
    for (final s in [
      StatusModel(id: 1, userId: 2, caption: 'Working on new chat UI designs', createdAt: statusNow.subtract(const Duration(hours: 2)).toIso8601String(), expiresAt: expires),
      StatusModel(id: 2, userId: 4, caption: 'Sprint planning done — lets ship it!', createdAt: statusNow.subtract(const Duration(hours: 5)).toIso8601String(), expiresAt: expires),
      StatusModel(id: 3, userId: 6, caption: 'All tests passing', createdAt: statusNow.subtract(const Duration(hours: 1)).toIso8601String(), expiresAt: expires),
      StatusModel(id: 4, userId: 7, caption: 'CI/CD pipeline green', createdAt: statusNow.subtract(const Duration(minutes: 30)).toIso8601String(), expiresAt: expires),
      StatusModel(id: 5, userId: 1, caption: 'OMAR Chat demo ready', createdAt: statusNow.subtract(const Duration(minutes: 15)).toIso8601String(), expiresAt: expires),
      StatusModel(id: 6, userId: 8, caption: 'Reviewing user stories for v2', createdAt: statusNow.subtract(const Duration(hours: 3)).toIso8601String(), expiresAt: expires),
      StatusModel(id: 7, userId: 3, caption: 'Studying for CEN306 exam', createdAt: statusNow.subtract(const Duration(minutes: 45)).toIso8601String(), expiresAt: expires),
      StatusModel(id: 8, userId: 5, caption: 'Team standup at 9 AM', createdAt: statusNow.subtract(const Duration(hours: 4)).toIso8601String(), expiresAt: expires),
    ]) {
      statuses.add(s.toMap());
    }

    final yesterday = DateTime.now().toUtc().subtract(const Duration(days: 1)).toIso8601String();
    final twoDaysAgo = DateTime.now().toUtc().subtract(const Duration(days: 2)).toIso8601String();
    for (final row in [
      {
        'id': 1,
        'contact_name': 'Mohamed',
        'contact_user_id': 2,
        'chat_id': 1,
        'call_type': 'voice',
        'is_group': 0,
        'is_outgoing': 1,
        'duration_seconds': 185,
        'created_at': hourAgo,
        'is_missed': 0,
      },
      {
        'id': 2,
        'contact_name': 'Ahmed',
        'contact_user_id': 3,
        'chat_id': 2,
        'call_type': 'video',
        'is_group': 0,
        'is_outgoing': 0,
        'duration_seconds': 420,
        'created_at': yesterday,
        'is_missed': 0,
      },
      {
        'id': 3,
        'contact_name': 'Project Team',
        'contact_user_id': null,
        'chat_id': 3,
        'call_type': 'voice',
        'is_group': 1,
        'is_outgoing': 1,
        'duration_seconds': 0,
        'created_at': twoDaysAgo,
        'is_missed': 1,
      },
    ]) {
      callHistory.add(row);
    }
  }

  /// Reset to fresh seed data (useful for testing).
  Future<void> reset() async {
    _initialized = false;
    await PersistenceService.instance.clear();
    await initialize();
  }

  /// Force save current state (JSON on web; SQLite already persisted on mobile).
  Future<void> flush() async {
    if (_db == null) await _persist();
  }
}