import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Map<String, dynamic> getCenterAndZoomForBounds(List<LatLng> points, {double padding = -0.3}) {
  if (points.isEmpty) return {'center': LatLng(0, 0), 'zoom': 15.0}; // Retorna un valor por defecto si no hay puntos

  // Inicializamos con valores extremos opuestos
  double minLat = double.infinity;
  double maxLat = -double.infinity;
  double minLng = double.infinity;
  double maxLng = -double.infinity;

  // Encontramos los límites de latitudes y longitudes
  for (var point in points) {
    if (point.latitude < minLat) minLat = point.latitude;
    if (point.latitude > maxLat) maxLat = point.latitude;
    if (point.longitude < minLng) minLng = point.longitude;
    if (point.longitude > maxLng) maxLng = point.longitude;
  }

  // Calculamos el centro
  LatLng center = LatLng(
    (minLat + maxLat) / 2,
    (minLng + maxLng) / 2,
  );

  // Ajuste del zoom basado en los límites (este ajuste está optimizado)
  double latDiff = maxLat - minLat;
  double lngDiff = maxLng - minLng;

  // Fórmula para calcular el nivel de zoom apropiado basado en la diferencia de latitud y longitud
  double zoomLat = log(360 / latDiff) / log(2); // Ajuste de zoom para la latitud
  double zoomLng = log(360 / lngDiff) / log(2); // Ajuste de zoom para la longitud

  // Tomamos el menor valor entre los dos para asegurarnos de que todos los puntos entren en la vista
  double zoom = min(zoomLat, zoomLng) - padding;

  // Limitar el zoom dentro de un rango adecuado
  zoom = zoom.clamp(2.0, 18.0);

  return {'center': center, 'zoom': zoom};
}

Widget buildMap({
  required MapController mapController,
  required LatLng? initialPosition,
  required List<Polyline> routePolylines,
  required List<Marker> markers,
  PositionCallback? onPositionChanged,
  VoidCallback? onMapReady,
  double initialZoom = 18.0,
}) {
  return FlutterMap(
    mapController: mapController, // Asignar el controlador al mapa
    options: MapOptions(
      initialCenter: initialPosition ?? LatLng(0, 0), // Usa initialCenter
      initialZoom: initialZoom,
      onPositionChanged: onPositionChanged,
      onMapReady: onMapReady,
    ),
    children: [
      TileLayer(
        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      ),
      PolylineLayer(
        polylines: routePolylines,
      ),
      MarkerLayer(
        markers: markers,
      ),
    ],
  );
}

Marker buildLocationMarker(LatLng position) {
  return Marker(
    point: position,
    width: 50.0,
    height: 50.0,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Color(0xFF4180E9),
            shape: BoxShape.circle,
          ),
        ),
      ],
    ),
  );
}

Marker buildInterestMarker({
  required LatLng position,
  String? text,
  String? base64Image,
  required BuildContext context,
}) {
  return Marker(
    point: position,
    width: 40.0,
    height: 40.0,
    alignment: Alignment.topCenter,
    child: GestureDetector(
      onTap: () {
        _showInfoDialog(context, text, base64Image);
      },
      child: Icon(
        Icons.location_on,
        color: Colors.blue,
        size: 40.0,
      ),
    ),
  );
}

void _showInfoDialog(BuildContext context, String? description, String? base64Image) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mostrar la imagen si está presente
          if (base64Image != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Image.memory(
                base64Decode(base64Image),
                // width: 100,
                // height: 100,
                fit: BoxFit.cover,
              ),
            ),
          // Mostrar el texto si está presente
          if (description != null)
            Text(
              description,
              style: TextStyle(fontSize: 16),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cerrar'),
        ),
      ],
    ),
  );
}

Polyline buildPreviousPloyline (routePoints) => Polyline(
  points: routePoints,
  strokeWidth: 5,
  color: Colors.green.withOpacity(0.8),
  pattern: StrokePattern.dashed(segments: [12, 8]),
  borderStrokeWidth: 4,
  borderColor: Colors.white.withOpacity(0.6),
);
