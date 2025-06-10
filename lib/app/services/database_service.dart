import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/scan_result.dart';

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE scans(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL,
        code_value TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');
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
}