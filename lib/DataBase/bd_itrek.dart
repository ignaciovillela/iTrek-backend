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

  // Insertar un usuario en la tabla de usuarios
  Future<int> insertUser(Map<String, dynamic> userData) async {
    final db = await instance.database;
    return await db.insert(
      'users',
      userData,
      conflictAlgorithm: ConflictAlgorithm.replace, // Reemplaza si ya existe
    );
  }

  // Actualizar el token de un usuario existente
  Future<int> updateUserToken(String username, String token) async {
    final db = await instance.database;

    // Verificar si el usuario ya existe
    final userExists = await getUserByUsername(username);
    if (userExists.isEmpty) {
      print("El usuario no existe. Inserción necesaria.");
      // Si el usuario no existe, inserta uno nuevo con el token
      return await insertUser({
        'username': username,
        'password': 'dummy_password', // Si no tienes el password, puedes usar un valor por defecto
        'token': token,
      });
    } else {
      // Si el usuario existe, actualiza solo el token
      print("Actualizando el token para el usuario: $username");
      return await db.update(
        'users',
        {'token': token},
        where: 'username = ?',
        whereArgs: [username],
      );
    }
  }

  // Consultar un usuario por su nombre de usuario
  Future<List<Map<String, dynamic>>> getUserByUsername(String username) async {
    final db = await instance.database;
    return await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // Obtener los usuarios que tienen un token almacenado
  Future<List<Map<String, dynamic>>> getUserWithToken() async {
    final db = await instance.database;
    return await db.query(
      'users',
      where: 'token IS NOT NULL AND token != ""',
    );
  }

  // Cerrar la base de datos
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
