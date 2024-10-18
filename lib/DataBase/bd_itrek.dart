import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Constructor privado para asegurar que solo haya una instancia de DatabaseHelper
  DatabaseHelper._init();

  // Getter para obtener la instancia de la base de datos
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('itrek_database.db');
    return _database!;
  }

  // Inicializa la base de datos con un nombre de archivo
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }



  // Crea la estructura de la base de datos (solo tabla valores)
  Future _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS valores (
  key TEXT PRIMARY KEY,      -- La clave es el identificador, puede ser 'username' o cualquier otro identificador
  value TEXT NOT NULL        -- El valor asociado, como el token u otros datos
)
''');
    print("Tabla 'valores' creada correctamente");
  }

  // Método para insertar o actualizar un nuevo par clave-valor en la tabla 'valores'
  Future<int> insertOrUpdateValue(String key, String value) async {
    final db = await instance.database;

    // Verifica si la clave ya existe
    final existingValue = await getValueByKey(key);
    if (existingValue.isEmpty) {
      // Si la clave no existe, inserta el nuevo valor
      return await db.insert(
        'valores',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      // Si la clave ya existe, actualiza el valor
      return await db.update(
        'valores',
        {'value': value},
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }

  // Método para obtener el valor de una clave específica
  Future<List<Map<String, dynamic>>> getValueByKey(String key) async {
    final db = await instance.database;
    return await db.query(
      'valores',
      where: 'key = ?',
      whereArgs: [key],
    );
  }

  // Método para cerrar la base de datos
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
