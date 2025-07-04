import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dream_diary.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE journals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );
  }

  static Future<int> createItem(String title, String description) async {
    final db = await database;
    return await db.insert(
      'journals',
      {
        'title': title,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    return await db.query('journals', orderBy: 'createdAt DESC');
  }

  static Future<int> updateItem(int id, String title, String description) async {
    final db = await database;
    return await db.update(
      'journals',
      {
        'title': title,
        'description': description,
        'createdAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> deleteItem(int id) async {
    final db = await database;
    return await db.delete(
      'journals',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dream_diary.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}