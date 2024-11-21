

import 'package:itrek/helpers/config.dart';

final apiUrl = '$BASE_URL/api';
final shareRouteUrl = '$apiUrl/share/route';

String shareRoute(String routeId) {
  final url = '$shareRouteUrl/$routeId/';
  return '🌲 ¡Hola trekker! Revisa esta ruta, puede ser perfecta para tu próxima aventura: $url ⛰️✨';
}