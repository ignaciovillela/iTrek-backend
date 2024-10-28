import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

Widget buildMap({
  required MapController mapController,
  required LatLng? initialPosition,
  required List<Polyline> routePolylines,
  required List<Marker> markers,
}) {
  return FlutterMap(
    mapController: mapController, // Asignar el controlador al mapa
    options: MapOptions(
      initialCenter: initialPosition ?? LatLng(0, 0), // Usa initialCenter
      initialZoom: 20.0, // Usa initialZoom
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


Widget buildMap2({
  required MapController mapController,
  required LatLng? initialPosition,
  required List<Polyline> routePolylines,
  required List<Marker> markers,
}) {
  return FlutterMap(
    mapController: mapController, // Asignar el controlador al mapa
    options: MapOptions(
      initialCenter: initialPosition ?? LatLng(0, 0), // Usa initialCenter
      initialZoom: 14.0, // Usa initialZoom
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

