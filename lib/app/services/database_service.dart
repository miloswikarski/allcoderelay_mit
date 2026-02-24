import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scan_result.dart';
import '../models/webhook.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('scans.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        code_value TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        webhook_error TEXT,
        last_webhook_attempt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE webhooks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        headers TEXT NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE webhooks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          url TEXT NOT NULL,
          headers TEXT NOT NULL,
          timestamp INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE scans ADD COLUMN webhook_error TEXT');
      await db.execute('ALTER TABLE scans ADD COLUMN last_webhook_attempt TEXT');
    }
  }

  Future<ScanResult> create(ScanResult scan) async {
    final db = await instance.database;
    final id = await db.insert('scans', scan.toMap());
    return scan.copyWith(id: id);
  }

  Future<List<ScanResult>> getAllScans() async {
    final db = await instance.database;
    final results = await db.query('scans', orderBy: 'timestamp DESC');
    return results.map((map) => ScanResult.fromMap(map)).toList();
  }

  Future<int> update(ScanResult scan) async {
    final db = await instance.database;
    return db.update(
      'scans',
      scan.toMap(),
      where: 'id = ?',
      whereArgs: [scan.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'scans',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAll() async {
    final db = await instance.database;
    return await db.delete('scans');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }

  // Webhook methods
  Future<Webhook> createWebhook(Webhook webhook) async {
    final db = await instance.database;
    final id = await db.insert('webhooks', webhook.toMap());
    return webhook.copyWith(id: id);
  }

  Future<List<Webhook>> getAllWebhooks() async {
    final db = await instance.database;
    final results = await db.query('webhooks', orderBy: 'timestamp DESC');
    return results.map((map) => Webhook.fromMap(map)).toList();
  }

  Future<Webhook?> getWebhookById(int id) async {
    final db = await instance.database;
    final results = await db.query(
      'webhooks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Webhook.fromMap(results.first);
  }

  Future<int> deleteWebhook(int id) async {
    final db = await instance.database;
    return await db.delete(
      'webhooks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasDefaultWebhook() async {
    final webhooks = await getAllWebhooks();
    return webhooks.any((w) => w.url == 'https://n8n.grapph.com/webhook/allcoderelay');
  }

  Future<Webhook?> getDefaultWebhook() async {
    final webhooks = await getAllWebhooks();
    for (final webhook in webhooks) {
      if (webhook.url == 'https://n8n.grapph.com/webhook/allcoderelay') {
        return webhook;
      }
    }
    return null;
  }
}