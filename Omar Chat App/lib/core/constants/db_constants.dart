class DbConstants {
  DbConstants._();

  static const String dbName = 'omar_chat.db';
  static const int dbVersion = 2;

  static const int currentUserId = 1;
  static const int editWindowMinutes = 10;
  static const int deleteForAllWindowMinutes = 5;

  static const String createUsers = '''
    CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT,
      job_title TEXT,
      avatar_path TEXT,
      bio TEXT,
      is_online INTEGER DEFAULT 0
    )
  ''';

  static const String createChats = '''
    CREATE TABLE chats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_type TEXT NOT NULL,
      title TEXT,
      last_message TEXT,
      last_message_time TEXT,
      background_path TEXT,
      created_at TEXT
    )
  ''';

  static const String createChatMembers = '''
    CREATE TABLE chat_members (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      role TEXT,
      FOREIGN KEY (chat_id) REFERENCES chats(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  ''';

  static const String createMessages = '''
    CREATE TABLE messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_id INTEGER NOT NULL,
      sender_id INTEGER NOT NULL,
      content TEXT,
      message_type TEXT,
      reply_to_message_id INTEGER,
      is_edited INTEGER DEFAULT 0,
      created_at TEXT,
      edited_at TEXT,
      deleted_at TEXT,
      is_deleted INTEGER DEFAULT 0,
      is_for_all INTEGER DEFAULT 0,
      read_at TEXT,
      FOREIGN KEY (chat_id) REFERENCES chats(id),
      FOREIGN KEY (sender_id) REFERENCES users(id)
    )
  ''';

  static const String createAttachments = '''
    CREATE TABLE attachments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      message_id INTEGER NOT NULL,
      file_name TEXT,
      file_path TEXT,
      file_type TEXT,
      file_size INTEGER,
      FOREIGN KEY (message_id) REFERENCES messages(id)
    )
  ''';

  static const String createStatuses = '''
    CREATE TABLE statuses (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      media_path TEXT,
      caption TEXT,
      created_at TEXT,
      expires_at TEXT,
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  ''';

  static const String createThemeSettings = '''
    CREATE TABLE theme_settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_id INTEGER NOT NULL,
      theme_name TEXT,
      background_path TEXT,
      FOREIGN KEY (chat_id) REFERENCES chats(id)
    )
  ''';

  static const String createBlockedUsers = '''
    CREATE TABLE blocked_users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      blocker_user_id INTEGER NOT NULL,
      blocked_user_id INTEGER NOT NULL,
      created_at TEXT,
      FOREIGN KEY (blocker_user_id) REFERENCES users(id),
      FOREIGN KEY (blocked_user_id) REFERENCES users(id)
    )
  ''';

  static const String createMutedChats = '''
    CREATE TABLE muted_chats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_id INTEGER NOT NULL,
      muted_until TEXT,
      is_muted INTEGER DEFAULT 1,
      FOREIGN KEY (chat_id) REFERENCES chats(id)
    )
  ''';

  static const String createUnreadCounts = '''
    CREATE TABLE unread_counts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      chat_id INTEGER NOT NULL,
      user_id INTEGER NOT NULL,
      unread_count INTEGER DEFAULT 0,
      last_read_message_id INTEGER,
      FOREIGN KEY (chat_id) REFERENCES chats(id),
      FOREIGN KEY (user_id) REFERENCES users(id)
    )
  ''';

  static const String createCallHistory = '''
    CREATE TABLE call_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      contact_name TEXT NOT NULL,
      contact_user_id INTEGER,
      chat_id INTEGER,
      call_type TEXT NOT NULL,
      is_group INTEGER DEFAULT 0,
      is_outgoing INTEGER DEFAULT 1,
      duration_seconds INTEGER DEFAULT 0,
      created_at TEXT,
      is_missed INTEGER DEFAULT 0,
      FOREIGN KEY (chat_id) REFERENCES chats(id),
      FOREIGN KEY (contact_user_id) REFERENCES users(id)
    )
  ''';

  static const List<String> allCreateStatements = [
    createUsers,
    createChats,
    createChatMembers,
    createMessages,
    createAttachments,
    createStatuses,
    createThemeSettings,
    createBlockedUsers,
    createMutedChats,
    createUnreadCounts,
    createCallHistory,
  ];
}
