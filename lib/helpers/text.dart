

import 'package:itrek/helpers/config.dart';

final apiUrl = '$BASE_URL/api';
final shareRouteUrl = '$BASE_URL/share/route';

String shareRoute(String routeId) {
  final url = '$shareRouteUrl/$routeId/';
  return '🌲 ¡Hola trekker! Revisa esta ruta, puede ser perfecta para tu próxima aventura: $url ⛰️✨';
}

String timeAgo(DateTime createdAt) {
  final Duration difference = DateTime.now().difference(createdAt);

  if (difference.inSeconds < 60) {
    return difference.inSeconds == 1
        ? 'hace 1 segundo'
        : 'hace ${difference.inSeconds} segundos';
  }

  if (difference.inMinutes < 60) {
    return difference.inMinutes == 1
        ? 'hace 1 minuto'
        : 'hace ${difference.inMinutes} minutos';
  }

  if (difference.inHours < 24) {
    return difference.inHours == 1
        ? 'hace 1 hora'
        : 'hace ${difference.inHours} horas';
  }

  if (difference.inDays < 30) {
    return difference.inDays == 1
        ? 'hace 1 día'
        : 'hace ${difference.inDays} días';
  }

  if (difference.inDays < 365) {
    final int months = (difference.inDays / 30).floor();
    return months == 1
        ? 'hace 1 mes'
        : 'hace $months meses';
  }

  final int years = (difference.inDays / 365).floor();
  return years == 1
      ? 'hace 1 año'
      : 'hace $years años';
}
