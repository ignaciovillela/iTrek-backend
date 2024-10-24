import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:itrek/config.dart';
import 'package:itrek/db.dart';

const GET = 'GET';
const POST = 'POST';
const PATCH = 'PATCH';
const DELETE = 'DELETE';

typedef StatusCallback = void Function(http.Response response);
typedef ErrorCallback = void Function(String errorMessage);

/// Realiza una solicitud HTTP con manejo de token opcional y cuerpo de datos,
/// y permite manejar diferentes estados de la respuesta mediante callbacks.
///
/// [method]: Método HTTP a utilizar (GET, POST, PATCH, DELETE).
/// [baseUrl]: URL base opcional, por defecto utiliza BASE_URL de la aplicación.
/// [url]: El endpoint al que se hará la solicitud.
/// [body]: Cuerpo opcional de la solicitud para métodos POST y PATCH.
/// [useToken]: Si es true, agrega un encabezado Authorization con un token obtenido de la base de datos.
/// [statusCallbacks]: Un mapa de códigos de estado específicos y sus callbacks correspondientes.
/// [onOk]: Callback para manejar respuestas exitosas (códigos de estado 200-299).
/// [onError]: Callback para manejar respuestas de error del lado del cliente (códigos de estado 400-499).
/// [onDefault]: Callback para cualquier otro código de estado no manejado.
/// [onConnectionError]: Callback para manejar errores de conexión o excepciones en la solicitud.
Future<http.Response?> makeRequest({
  required String method, // GET, POST, PATCH, DELETE
  String? baseUrl,
  required String url,
  Map<String, dynamic>? body, // Cuerpo opcional para POST y PATCH
  bool useToken = true, // Determina si se usa el token
  Map<dynamic, StatusCallback>? statusCallbacks, // Callbacks específicos para códigos o rangos de estado
  StatusCallback? onDefault, // Callback para cualquier otro código de estado
  StatusCallback? onOk, // Callback para rangos de éxito (200-299)
  StatusCallback? onError, // Callback para rangos de error (400-499)
  ErrorCallback? onConnectionError, // Callback para manejar errores de conexión
}) async {
  final token = useToken ? await db.get(db.token) : null;

  final headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    if (useToken && token != null) 'Authorization': 'Token $token',
  };
  baseUrl = baseUrl ?? BASE_URL;
  Uri uri = Uri.parse('$baseUrl/$url');

  http.Response response;

  try {
    switch (method.toUpperCase()) {
      case GET:
        response = await http.get(uri, headers: headers);
        break;
      case POST:
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case PATCH:
        response = await http.patch(uri, headers: headers, body: jsonEncode(body));
        break;
      case DELETE:
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Invalid HTTP method: $method');
    }

    // Decodificar el cuerpo de la respuesta con utf8
    response = http.Response(utf8.decode(response.bodyBytes), response.statusCode, headers: response.headers);

    // Ejecutar callbacks basados en el código de estado
    bool callbackEjecutado = false;

    if (statusCallbacks != null) {
      statusCallbacks.forEach((clave, callback) {
        if (clave is int && clave == response.statusCode) {
          // Si la clave es un entero y coincide con el código de estado
          callback.call(response);
          callbackEjecutado = true;
        } else if (clave is List<int> && clave.contains(response.statusCode)) {
          // Si la clave es una lista y contiene el código de estado
          callback.call(response);
          callbackEjecutado = true;
        }
      });
    }

    if (!callbackEjecutado) {
      // Si no se ejecutó un callback específico, aplicamos los genéricos
      if (onOk != null && response.statusCode >= 200 && response.statusCode < 300) {
        onOk.call(response);
      } else if (onError != null && response.statusCode >= 400 && response.statusCode < 500) {
        onError.call(response);
      } else if (onDefault != null) {
        onDefault.call(response);
      }
    }

    return response; // Devolver la respuesta decodificada
  } catch (e) {
    // Manejar errores de conexión u otros
    if (onConnectionError != null) {
      onConnectionError("Error de conexión: $e");
    } else {
      print('Error de conexión: $e');
    }
    return null; // Devolver null en caso de error
  }
}
