import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('itrek_database.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT NOT NULL,
  password TEXT NOT NULL,
  token TEXT
)
''');
  }

  Future<int> insertUser(Map<String, dynamic> userData) async {
    final db = await instance.database;
    return await db.insert('users', userData, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateUserToken(String username, String token) async {
    final db = await instance.database;
    return await db.update(
        'users',
        {'token': token},
        where: 'username = ?',
        whereArgs: [username]
    );
  }

  Future<List<Map<String, dynamic>>> getUserByUsername(String username) async {
    final db = await instance.database;
    return await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username]
    );
  }

  // Nuevo método que devuelve si hay un token almacenado
  Future<List<Map<String, dynamic>>> getUserWithToken() async {
    final db = await instance.database;
    return await db.query(
      'users',
      where: 'token IS NOT NULL AND token != ""', // Verifica si existe un token no vacío
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
