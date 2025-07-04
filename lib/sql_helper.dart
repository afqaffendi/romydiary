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
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'dream_diary.db');
      print('Database path: $path');
      
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
          print('Created journals table');
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  static Future<int> createItem(String title, String description) async {
    try {
      final db = await database;
      final createdAt = DateTime.now().toIso8601String();
      
      final id = await db.insert(
        'journals',
        {
          'title': title,
          'description': description,
          'createdAt': createdAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      print('Created item with ID: $id');
      return id;
    } catch (e) {
      print('Error creating item: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final db = await database;
      final items = await db.query(
        'journals',
        orderBy: 'createdAt DESC',
      );
      print('Fetched ${items.length} items');
      return items;
    } catch (e) {
      print('Error fetching items: $e');
      rethrow;
    }
  }

  static Future<int> updateItem(int id, String title, String description) async {
    try {
      final db = await database;
      final result = await db.update(
        'journals',
        {
          'title': title,
          'description': description,
          'createdAt': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Updated $result item(s)');
      return result;
    } catch (e) {
      print('Error updating item: $e');
      rethrow;
    }
  }

  static Future<int> deleteItem(int id) async {
    try {
      final db = await database;
      final result = await db.delete(
        'journals',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Deleted $result item(s)');
      return result;
    } catch (e) {
      print('Error deleting item: $e');
      rethrow;
    }
  }

  static Future<void> deleteDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'dream_diary.db');
      await databaseFactory.deleteDatabase(path);
      print('Database deleted');
      _database = null;
    } catch (e) {
      print('Error deleting database: $e');
      rethrow;
    }
  }
}