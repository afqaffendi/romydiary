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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) {
          await db.execute('''
            CREATE TABLE journals(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              title TEXT NOT NULL,
              description TEXT,
              createdAt TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  static Future<int> createItem(String title, String? description) async {
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
    return await db.query(
      'journals',
      orderBy: 'createdAt DESC',
    );
  }

  static Future<int> updateItem(
    int id,
    String title,
    String? description,
  ) async {
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

  static Future<int> getDreamCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM journals');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<void> deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'dream_diary.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  static Future<bool> doesTableExist(String tableName) async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName'"
    );
    return result.isNotEmpty;
  }

  static Future<List<Map<String, dynamic>>> getFilteredItems({
  String? searchQuery,
  DateTime? startDate,
  DateTime? endDate,
}) async {
  final db = await database;
  
  String where = '1=1';
  List<Object?> whereArgs = [];

  if (searchQuery != null && searchQuery.isNotEmpty) {
    where += ' AND (title LIKE ? OR description LIKE ?)';
    whereArgs.add('%$searchQuery%');
    whereArgs.add('%$searchQuery%');
  }

  if (startDate != null) {
    where += ' AND createdAt >= ?';
    whereArgs.add(startDate.toIso8601String());
  }

  if (endDate != null) {
    where += ' AND createdAt <= ?';
    whereArgs.add(endDate.toIso8601String());
  }

  return await db.query(
    'journals',
    where: where,
    whereArgs: whereArgs,
    orderBy: 'createdAt DESC',
  );
}
}