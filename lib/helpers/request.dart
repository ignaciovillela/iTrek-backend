import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:itrek/helpers/config.dart';
import 'package:itrek/helpers/db.dart';

const GET = 'GET';
const POST = 'POST';
const PATCH = 'PATCH';
const DELETE = 'DELETE';
const PUT = 'PUT';

const LOGIN =           'api/auth/login/';
const LOGIN_CHECK =     'api/auth/check-login/';
const LOGOUT =          'api/auth/logout/';

const USER_CREATE =     'api/users/create/';
const USER_UPDATE =     'api/users/update-profile/';
const USER_DELETE =     'api/users/delete-account/';

const ROUTES =          'api/routes/';
const ROUTE_DETAIL =    'api/routes/{id}/';
const ROUTE_SHARE =     'api/routes/{id}/share/{usuarioId}/';
const ROUTE_RATING =    'api/routes/{id}/rate/';

const SEARCH_USER =     'api/users/search?q={query}';
const PASSWORD_CHANGE = 'api/users/change-password/';

typedef StatusCallback = void Function(http.Response response);
typedef ErrorCallback = void Function(String errorMessage);

String formatUrl(String url, Map<String, dynamic>? urlVars) {
  if (urlVars != null) {
    urlVars.forEach((key, value) {
      url = url.replaceAll('{$key}', value.toString());
    });
  }
  return url;
}

/// Realiza una solicitud HTTP con soporte para diferentes métodos (GET, POST, PATCH, DELETE),
/// manejo opcional de token, parámetros de URL dinámicos, cuerpo de la solicitud,
/// y control de respuestas a través de callbacks.
///
/// [method]: El método HTTP a utilizar, como GET, POST, PATCH, DELETE.
/// [baseUrl]: URL base opcional. Si no se proporciona, se utilizará BASE_URL configurada en la aplicación.
/// [url]: El endpoint al que se hará la solicitud. Puede contener placeholders como {id}, {usuarioId}, etc.
/// [urlVars]: Mapa de parámetros opcionales para reemplazar en la URL, donde las llaves corresponden a los placeholders en la URL.
/// [body]: Cuerpo opcional de la solicitud para métodos POST y PATCH, codificado en JSON.
/// [useToken]: Si es true, agrega el token almacenado en la base de datos en el encabezado Authorization.
/// [statusCallbacks]: Mapa opcional de códigos de estado HTTP (int o List<int>) y sus callbacks específicos.
/// [onOk]: Callback para manejar respuestas exitosas (códigos de estado 200-299).
/// [onError]: Callback para manejar respuestas de error del lado del cliente (códigos de estado 400-499).
/// [onDefault]: Callback para manejar cualquier otro código de estado no manejado explícitamente en [statusCallbacks].
/// [onConnectionError]: Callback para manejar errores de conexión o excepciones en la solicitud.
/// [customHeaders]: Mapa opcional de headers personalizados que se agregarán a los headers estándar.
///
/// Devuelve un `Future<http.Response?>` que contiene la respuesta decodificada o `null` en caso de error de conexión.
Future<http.Response?> makeRequest({
  required String method, // GET, POST, PATCH, DELETE
  String? baseUrl, // URL base opcional, si no se proporciona se utiliza BASE_URL
  required String url, // URL del endpoint con placeholders opcionales
  bool isFullUrl = false,
  Map<String, dynamic>? urlVars, // Parámetros opcionales que serán reemplazados en la URL
  Map<String, dynamic>? body, // Cuerpo opcional para POST y PATCH, codificado en JSON
  bool useToken = true, // Determina si se usa el token almacenado en la base de datos
  Map<dynamic, StatusCallback>? statusCallbacks, // Callbacks para códigos específicos de estado
  StatusCallback? onOk, // Callback para respuestas exitosas (códigos 200-299)
  StatusCallback? onError, // Callback para respuestas de error del lado del cliente (códigos 400-499)
  StatusCallback? onDefault, // Callback genérico para otros códigos de estado
  ErrorCallback? onConnectionError, // Callback para manejar errores de conexión o excepciones
  Map<String, String>? customHeaders, // Headers personalizados opcionales
}) async {
  // Obtención del token si se requiere
  final token = useToken ? await db.values.get(db.values.token) : null;

  // Construcción de los headers de la solicitud
  final headers = {
    'Content-Type': 'application/json; charset=UTF-8',
    if (useToken && token != null) 'Authorization': 'Token $token',
    if (customHeaders != null) ...customHeaders, // Agregar headers personalizados
  };

  if (!isFullUrl) {
    // Reemplazar los parámetros en la URL
    url = formatUrl(url, urlVars);
    baseUrl = baseUrl ?? BASE_URL;
    url = '$baseUrl/$url';
  }
  Uri uri = Uri.parse(url);
  http.Response response;

  try {
    // Ejecutar la solicitud HTTP en función del método
    switch (method.toUpperCase()) {
      case GET:
        response = await http.get(uri, headers: headers);
        break;
      case POST:
        response = await http.post(uri, headers: headers, body: jsonEncode(body));
        break;
      case PUT:
        response = await http.put(uri, headers: headers, body: jsonEncode(body));
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

    // Decodificar el cuerpo de la respuesta para manejar caracteres especiales
    response = http.Response(utf8.decode(response.bodyBytes), response.statusCode, headers: response.headers);

    // Ejecutar callbacks específicos según el código de estado
    bool callbackEjecutado = false;

    if (statusCallbacks != null) {
      statusCallbacks.forEach((clave, callback) {
        if (clave is int && clave == response.statusCode) {
          // Si la clave es un código de estado específico
          callback.call(response);
          callbackEjecutado = true;
        } else if (clave is List<int> && clave.contains(response.statusCode)) {
          // Si la clave es una lista que contiene el código de estado
          callback.call(response);
          callbackEjecutado = true;
        }
      });
    }

    // Aplicar callbacks genéricos si no se ha ejecutado un callback específico
    if (!callbackEjecutado) {
      if (onOk != null && response.statusCode >= 200 && response.statusCode < 300) {
        onOk.call(response);
      } else if (onError != null && response.statusCode >= 400 && response.statusCode < 500) {
        onError.call(response);
      } else if (onDefault != null) {
        onDefault.call(response);
      }
    }

    // Devolver la respuesta decodificada
    return response;
  } catch (e) {
    // Manejar errores de conexión o excepciones
    if (onConnectionError != null) {
      onConnectionError("Error de conexión: $e");
    } else {
      print('Error de conexión: $e');
    }
    return null; // Devolver null en caso de error
  }
}
