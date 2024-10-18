import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  final username = 'username';
  final token = 'token';

  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  // Constructor privado para asegurar que solo haya una instancia de DatabaseHelper
  DatabaseHelper._init();

  // Getter para obtener la instancia de la base de datos
  Future<Database> get __database async {
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
  Future<int> create(String key, String value) async {
    print('Inserting or updating value - Key: $key, Value: $value');
    final db = await instance.__database;

    try {
      // Inserta el valor, y si ya existe la clave, reemplaza el valor.
      final result = await db.insert(
        'valores',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace, // Actualiza si la clave existe
      );

      print('Insert or update successful for key: $key');
      return result; // Retorna el número de la fila afectada
    } catch (e) {
      print('Failed to insert or update value: $e');
      return -1; // Retorna -1 si ocurre un error
    }
  }

// Method to get the value of a specific key and return its original type
  Future<Object?> get(String key) async {
    final db = await instance.__database;
    final result = await db.query(
      'valores',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      // Retornar el valor tal como está en su tipo original
      return result.first['value'];
    } else {
      // Si no se encuentra el valor, retornamos null
      return null;
    }
  }

  // Method to get the value of a specific key and return its original type
  Future<Object?> delete(String key) async {
    final db = await instance.__database;
    final result = await db.query(
      'valores',
      where: 'key = ?',
      whereArgs: [key],
    );

    if (result.isNotEmpty) {
      // Retornar el valor tal como está en su tipo original
      return result.first['value'];
    } else {
      // Si no se encuentra el valor, retornamos null
      return null;
    }
  }

  // Método para cerrar la base de datos
  Future close() async {
    final db = await instance.__database;
    db.close();
  }
}

final db = DatabaseHelper.instance;
