import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart'; // Para generar UUIDs

// Clase base para gestionar la base de datos
class DatabaseHelper {
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
    print("Se llama al _initDb");
    return await openDatabase(path, version: 1, onCreate: _createDB, onUpgrade: _onUpgrade);
  }

  // Crea la estructura de la base de datos
  Future _createDB(Database db, int version) async {
    await createTables(db); // Llama a este método para crear todas las tablas
  }

  Future _onUpgrade(db, oldVersion, newVersion) async {
    updateTables(db, oldVersion, newVersion);
  }

  Future<void> createTables(Database db) async {}


  Future<void> updateTables(Database db, oldVersion, newVersion) async {}

  // Método para cerrar la base de datos
  Future close() async {
    final db = await database;
    db.close();
  }
}

// ValuesHelper: gestiona la tabla 'valores'
class ValuesHelper extends DatabaseHelper {
  static final ValuesHelper instance = ValuesHelper._init();

  final String username = 'username';
  final String email = 'email';
  final String first_name = 'first_name';
  final String last_name = 'last_name';
  final String biografia = 'biografia';
  final String imagen_perfil = 'imagen_perfil';
  final String token = 'token';

  // Constructor privado
  ValuesHelper._init() : super._init();

  @override
  Future<void> createTables(Database db) async {
    print("Se llama al createTables de values");
    await _createValuesTable(db);
  }

  // Método para crear la tabla 'valores'
  Future _createValuesTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS valores (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    print("Tabla 'valores' creada correctamente");
  }

  // Métodos para gestionar los datos en la tabla 'valores'
  Future<int> create(String key, String value) async {
    final db = await database;  // Accede al getter directamente
    try {
      final result = await db.insert(
        'valores',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return result;
    } catch (e) {
      return -1;
    }
  }

  Future<String?> get(String key) async {
    final db = await database;  // Accede al getter directamente
    final result = await db.query('valores', where: 'key = ?', whereArgs: [key]);
    return result.isNotEmpty ? result.first['value'] as String : null;
  }

  Future<int> delete(String key) async {
    final db = await database;  // Accede al getter directamente
    return await db.delete('valores', where: 'key = ?', whereArgs: [key]);
  }

  Future<void> setUserData(Map<String, dynamic> data) async {
    final fields = {
      'username': username,
      'email': email,
      'first_name': first_name,
      'last_name': last_name,
      'biografia': biografia,
      'imagen_perfil': imagen_perfil,
      'token': token,
    };

    for (var entry in fields.entries) {
      final key = entry.key;
      final dbKey = entry.value;

      if (data.containsKey(key)) {
        await create(dbKey, data[key]);
      }
    }
  }

  Future<Map<String, String?>> getUserData() async {
    final fields = {
      'username': username,
      'email': email,
      'first_name': first_name,
      'last_name': last_name,
      'biografia': biografia,
      'imagen_perfil': imagen_perfil,
      'token': token,
    };

    final Map<String, String?> data = {};

    for (var entry in fields.entries) {
      final key = entry.key;
      final dbKey = entry.value;

      final value = await get(dbKey);
      if (value != null) {
        data[key] = value;
      }
    }

    return data;
  }
}

// RoutesHelper: gestiona las tablas 'rutas' y 'puntos'
class RoutesHelper extends DatabaseHelper {
  static final RoutesHelper instance = RoutesHelper._init();
  final Uuid uuid = Uuid(); // Para generar UUIDs locales

  // Constructor privado
  RoutesHelper._init() : super._init();

  @override
  Future<void> createTables(Database db) async {
    print("Se llama al createTables de rutas");
    await _createRouteTable(db);
    await _createPuntosTable(db);
  }

  // Método para crear la tabla 'rutas'
  Future _createRouteTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rutas (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        dificultad TEXT,
        creado_en TEXT,
        distancia_km REAL,
        tiempo_estimado_horas REAL,
        usuario_username TEXT,
        usuario_email TEXT,
        usuario_first_name TEXT,
        usuario_last_name TEXT,
        usuario_biografia TEXT,
        usuario_imagen_perfil TEXT,
        publica INTEGER NOT NULL,
        local BOOLEAN NOT NULL
      )
    ''');
    print("Tabla 'rutas' creada correctamente");
  }

  // Método para crear la tabla 'puntos'
  Future _createPuntosTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS puntos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ruta_id TEXT NOT NULL,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        orden INTEGER NOT NULL,
        interes_descripcion TEXT,
        interes_imagen TEXT,
        FOREIGN KEY (ruta_id) REFERENCES rutas(id) ON DELETE CASCADE
      )
    ''');
    print("Tabla 'puntos' creada correctamente");
  }

  // Método para crear una nueva ruta local (con UUID y 'local' en true)
  Future<String?> createLocalRoute(Map<String, dynamic> routeData) async {
    final db = await database;  // Accede al getter directamente
    try {
      String localId = uuid.v4();

      final result = await db.insert(
        'rutas',
        {...routeData, 'id': localId, 'local': 1},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (result != 0) {
        return localId;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Método para crear una ruta desde el backend (sin 'local_id' y 'local' en false)
  Future<int> createBackendRoute(Map<String, dynamic> routeData) async {
    final db = await database;  // Accede al getter directamente
    try {
      final result = await db.insert(
        'rutas',
        {'local': false, ...routeData}, // El 'id' viene del backend
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return result;
    } catch (e) {
      return -1;
    }
  }

  // Método para crear un punto asociado a una ruta
  Future<int?> createPunto(String rutaId, Map<String, dynamic> puntoData) async {
    final db = await database;  // Accede al getter directamente
    try {
      final int puntoId = await db.insert(
        'puntos',
        {'ruta_id': rutaId, ...puntoData},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return puntoId; // Retorna el ID del punto insertado
    } catch (e) {
      // En caso de error, imprime el error y retorna null
      print('Error al insertar punto: $e');
      return null;
    }
  }

  // Método para actualizar un punto asociado a una ruta
  Future<int?> updatePunto(int puntoId, Map<String, dynamic> puntoData) async {
    final db = await database;
    try {
      final int count = await db.update(
        'puntos',
        puntoData,
        where: 'id = ?',
        whereArgs: [puntoId],
      );

      return count > 0 ? puntoId : null;
    } catch (e) {
      // En caso de error, imprime el error y retorna null
      print('Error al actualizar punto: $e');
      return null;
    }
  }

  // Método para obtener las rutas locales (con UUID como 'id')
  Future<List<Map<String, dynamic>>> getLocalRoutes() async {
    final db = await database;
    return await db.query('rutas', where: 'local = ?', whereArgs: [true]);
  }

  // Método para obtener las rutas sincronizadas (con ID del backend)
  Future<List<Map<String, dynamic>>> getBackendRoutes() async {
    final db = await database;
    return await db.query('rutas', where: 'local = ?', whereArgs: [false]);
  }

  // Método para obtener todas las rutas (locales y sincronizadas)
  Future<List<Map<String, dynamic>>> getAllRoutes() async {
    final db = await database;
    return await db.query('rutas');
  }

  // Obtener puntos asociados a una ruta (tanto locales como del backend)
  Future<List<Map<String, dynamic>>> getPuntosByRutaId(String rutaId) async {
    final db = await database;
    return await db.query('puntos', where: 'ruta_id = ?', whereArgs: [rutaId]);
  }

  // Obtener una ruta por su ID
  Future<Map<String, dynamic>?> getRouteById(String id) async {
    final db = await database;
    final result = await db.query('rutas', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  // Eliminar una ruta por su ID
  Future<int> deleteRoute(String id) async {
    final db = await database;
    return await db.delete('rutas', where: 'id = ?', whereArgs: [id]);
  }
}

// Clase que unifica los helpers
class _DbHelper {
  final values = ValuesHelper.instance;
  final routes = RoutesHelper.instance;

  // Inicializa la base de datos asegurando que ambas tablas se creen
  Future<void> initDatabase() async {
    final db = await values.database;  // Inicializa la base de datos
    await values.createTables(db);     // Asegúrate de crear las tablas de valores
    await routes.createTables(db);     // Asegúrate de crear las tablas de rutas
  }
}

final db = _DbHelper();
