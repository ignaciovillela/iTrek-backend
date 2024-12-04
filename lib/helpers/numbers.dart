
import 'package:intl/intl.dart';

final NumberFormat conDecimales = NumberFormat("#,##0.0", "es_CL");
final NumberFormat sinDecimales = NumberFormat("#,##0", "es_CL");

String formatDistancia(dynamic distancia) {
  if (distancia == null) return '0'; // Si no hay distancia, devuelve "0"

  double distanciaValue = double.tryParse(distancia.toString()) ?? 0.0;

  // Configura el formateador para Chile
  if (distanciaValue < 100) {
    return conDecimales.format(distanciaValue); // Formato con un decimal
  } else {
    return sinDecimales.format(distanciaValue); // Formato sin decimales
  }
}

String formatTiempo(int minutosTotales) {
  final Duration duracion = Duration(minutes: minutosTotales);
  final int horas = duracion.inHours;
  final int minutos = duracion.inMinutes % 60;
  return '${horas.toString().padLeft(2, '0')}:${minutos.toString().padLeft(2, '0')}';
}
