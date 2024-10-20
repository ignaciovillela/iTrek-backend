import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:itrek/config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Solicitar permisos de ubicación en primer plano y, si es necesario, en segundo plano
Future<void> requestBackgroundPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error('Los permisos de ubicación están denegados permanentemente.');
  }

  if (permission == LocationPermission.whileInUse) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always) {
      return Future.error('Se necesita permiso de ubicación en segundo plano.');
    }
  }
}

// Función para convertir una lista de coordenadas LatLng a un formato JSON
List<Map<String, dynamic>> convertirAFormato(List<LatLng> listaCoords) {
  return List<Map<String, dynamic>>.generate(listaCoords.length, (index) {
    return {
      "latitud": listaCoords[index].latitude,
      "longitud": listaCoords[index].longitude,
      "orden": index + 1,
    };
  });
}

// Función para enviar una ruta al backend mediante una solicitud HTTP POST
Future<int?> postRuta(Map<String, dynamic> rutaData) async {
  String url = '$BASE_URL/api/rutas/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(rutaData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return responseData['id'];
    } else {
      print('Error al crear la ruta: ${response.statusCode}');
    }
  } catch (e) {
    print('Error en la solicitud: $e');
  }
  return null;
}

// Función para actualizar la ruta con datos adicionales usando PATCH
Future<void> _updateRuta(int id, String nombre, String descripcion, String dificultad, double distanciaKm, double tiempoEstimadoHoras) async {
  final response = await http.patch(
    Uri.parse('$BASE_URL/api/rutas/$id/'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'nombre': nombre,
      'descripcion': descripcion,
      'dificultad': dificultad,
      'distancia_km': distanciaKm,
      'tiempo_estimado_horas': tiempoEstimadoHoras,
    }),
  );

  if (response.statusCode == 200) {
    print('Ruta actualizada con éxito');
  } else {
    print('Error al actualizar la ruta: ${response.statusCode}');
  }
}

// Página principal del mapa donde se graba la ruta usando flutter_map
class RegistrarRuta extends StatefulWidget {
  const RegistrarRuta({super.key});

  @override
  RegistrarRutaState createState() => RegistrarRutaState();
}

class RegistrarRutaState extends State<RegistrarRuta> {
  final List<Marker> _markers = [];
  final List<LatLng> _routeCoords = [];
  Polyline _routePolyline = Polyline(
    points: [],
    strokeWidth: 5,
    color: Colors.blue,
  );
  bool _isRecording = false;
  Timer? _timer;
  Timer? _locationTimer;
  int _seconds = 0;
  double _distanceTraveled = 0.0;
  LatLng? _lastPosition;
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    await requestBackgroundPermission();
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(),
    );
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          point: _initialPosition!,
          child: Icon(Icons.location_on, color: Colors.blue),
        ),
      );
    });
  }

  Future<void> _iniciarRegistro() async {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _seconds++;
          });
        }
      });

      _locationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
        _lastPosition ??= _initialPosition;

        Position position = await Geolocator.getCurrentPosition(locationSettings: AndroidSettings());
        final newPosition = LatLng(position.latitude, position.longitude);

        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        _distanceTraveled += distance;

        setState(() {
          _routeCoords.add(newPosition);
          _lastPosition = newPosition;

          _routePolyline = Polyline(
            points: _routeCoords,
            strokeWidth: 5,
            color: Colors.blue,
          );

          _markers.add(
            Marker(
              point: newPosition,
              child: Icon(Icons.location_on, color: Colors.red),
            ),
          );
        });
      });
    } else {
      _timer?.cancel();
      _locationTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ruta'),
        backgroundColor: Colors.green[700],
      ),
      body: _initialPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _initialPosition ?? LatLng(0, 0), // Usa un valor predeterminado si _initialPosition es null
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              PolylineLayer(
                polylines: [_routePolyline],
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          )
,
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              children: [
                Text('Tiempo: ${_formatTime(_seconds)}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('Distancia: ${_formatDistance(_distanceTraveled)}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 60,
            bottom: 30,
            child: ElevatedButton(
              onPressed: _isRecording ? _iniciarRegistro : null,
              child: Text(_isRecording ? 'Finalizar Ruta' : 'Iniciar Registro'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(2)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }
}
