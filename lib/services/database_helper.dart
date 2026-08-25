import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('chat_offline.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message_id TEXT NOT NULL,
        peer_address TEXT NOT NULL,
        sender TEXT NOT NULL,
        text TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE messages ADD COLUMN message_id TEXT DEFAULT ""');
      await db.execute('ALTER TABLE messages ADD COLUMN status TEXT DEFAULT "SENT"');
    }
  }

  Future<int> insertMessage(MessageModel message) async {
    final db = await instance.database;
    return await db.insert('messages', message.toMap());
  }

  Future<int> updateMessageStatus(String messageId, String status) async {
    final db = await instance.database;
    return await db.update(
      'messages',
      {'status': status},
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }

  Future<List<MessageModel>> getMessages(String peerAddress) async {
    final db = await instance.database;
    final result = await db.query(
      'messages',
      where: 'peer_address = ?',
      whereArgs: [peerAddress],
      orderBy: 'id ASC',
    );

    return result.map((json) => MessageModel.fromMap(json)).toList();
  }
}