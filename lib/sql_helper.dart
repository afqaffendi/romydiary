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
    final path = join(dbPath, 'diary.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE journals(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            createdAt TEXT
          )
        ''');
        print('Database table created successfully');
      },
    );
  }

  static Future<void> ensureTableExists() async {
    final db = await database;
    try {
      await db.rawQuery('SELECT 1 FROM journals LIMIT 1');
    } catch (e) {
      print('Table missing, recreating...');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS journals(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT,
          description TEXT,
          createdAt TEXT
        )
      ''');
    }
  }

  static Future<int> createItem(String title, String description) async {
    final db = await database;
    await ensureTableExists();
    return await db.insert('journals', {
      'title': title,
      'description': description,
      'createdAt': DateTime.now().toString(),
    });
  }

  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await database;
    await ensureTableExists();
    return await db.query('journals', orderBy: 'id DESC');
  }

  static Future<int> updateItem(int id, String title, String description) async {
    final db = await database;
    await ensureTableExists();
    return await db.update(
      'journals',
      {
        'title': title,
        'description': description,
        'createdAt': DateTime.now().toString(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> deleteItem(int id) async {
    final db = await database;
    await ensureTableExists();
    await db.delete('journals', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> printDbPath() async {
    final path = join(await getDatabasesPath(), 'diary.db');
    print('Database location: $path');
  }
}