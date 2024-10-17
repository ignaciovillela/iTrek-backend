import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Función para solicitar permisos y obtener la ubicación actual del usuario
Future<LatLng?> obtenerUbicacion() async {
  try {
    // Verificar si los servicios de ubicación están habilitados
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Si los servicios de ubicación están deshabilitados, puedes mostrar un mensaje al usuario
      print('Los servicios de ubicación están deshabilitados.');
      return Future.error('Los servicios de ubicación están deshabilitados.');
    }

    // Verificar los permisos de ubicación
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Si los permisos son denegados, solicitarlos
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Si el usuario sigue denegando los permisos, retorna un error
        print('Permisos de ubicación denegados.');
        return Future.error('Permisos de ubicación denegados.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Si los permisos están denegados permanentemente, no se pueden pedir más permisos
      print('Permisos de ubicación denegados permanentemente.');
      return Future.error('Permisos de ubicación denegados permanentemente.');
    }

    // Si los permisos están concedidos, obtener la ubicación actual
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // Retorna las coordenadas como LatLng
    return LatLng(position.latitude, position.longitude);
  } catch (e) {
    // Manejo de cualquier otro error que ocurra al obtener la ubicación
    print('Error al obtener la ubicación: $e');
    return Future.error('Error al obtener la ubicación: $e');
  }
}

void obtenerUbicacionActual() async {
  try {
    LatLng? ubicacion = await obtenerUbicacion();
    if (ubicacion != null) {
      print('Ubicación actual: ${ubicacion.latitude}, ${ubicacion.longitude}');
      // Actualiza tu estado o mapa con la ubicación obtenida
    }
  } catch (e) {
    print('Error al obtener la ubicación: $e');
    // Maneja el error aquí (por ejemplo, mostrando un mensaje al usuario)
  }
}
