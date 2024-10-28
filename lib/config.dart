import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;

String getEnvVariable(String key) {
  final value = dotenv.env[key];
  if (value == null || value.isEmpty) {
    throw Exception('La variable $key no está definida en el archivo .env');
  }
  return value;
}

final String BASE_URL = getEnvVariable('BASE_URL');
