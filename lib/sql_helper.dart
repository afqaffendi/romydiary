import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SQLHelper {
  static Future<void> createTables(Database database) async {
    await database.execute("""
      CREATE TABLE journals(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        title TEXT,
        description TEXT,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    """);
  }

  static Future<Database> db() async {
    return openDatabase(
      join(await getDatabasesPath(), 'journal.db'),
      version: 1,
      onCreate: (Database database, int version) async {
        await createTables(database);
      },
    );
  }

  static Future<int> createItem(String title, String description) async {
    final db = await SQLHelper.db();
    final data = {'title': title, 'description': description};
    return await db.insert('journals', data);
  }

  static Future<List<Map<String, dynamic>>> getItems() async {
    final db = await SQLHelper.db();
    return db.query('journals', orderBy: "id DESC");
  }

  static Future<int> updateItem(
      int id, String title, String description) async {
    final db = await SQLHelper.db();
    final data = {
      'title': title,
      'description': description,
      'createdAt': DateTime.now().toString()
    };
    return await db.update('journals', data, where: "id = ?", whereArgs: [id]);
  }

  static Future<void> deleteItem(int id) async {
    final db = await SQLHelper.db();
    await db.delete('journals', where: "id = ?", whereArgs: [id]);
  }
}