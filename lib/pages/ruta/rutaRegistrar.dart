import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:itrek/config.dart';
import 'package:itrek/pages/ruta/RutaFormPage.dart';
import 'package:itrek/request/request.dart';
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
  try {
    final response = await makeRequest(
      method: 'POST',
      url: '$BASE_URL/api/rutas/',
      body: rutaData,
      useToken: true, // Usamos el token si es necesario
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
  try {
    final response = await makeRequest(
      method: 'PATCH',
      url: '$BASE_URL/api/rutas/$id/',
      body: {
        'nombre': nombre,
        'descripcion': descripcion,
        'dificultad': dificultad,
        'distancia_km': distanciaKm,
        'tiempo_estimado_horas': tiempoEstimadoHoras,
      },
      useToken: true, // Se requiere token para la autenticación
    );

    if (response.statusCode == 200) {
      print('Ruta actualizada con éxito');
    } else {
      print('Error al actualizar la ruta: ${response.statusCode}');
    }
  } catch (e) {
    print('Error al actualizar la ruta: $e');
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
  int _seconds = 0;
  final double _distanceTraveled = 0.0;
  LatLng? _lastPosition;
  LatLng? _initialPosition;
  StreamSubscription<Position>? _positionStreamSubscription;
  MapController mapController = MapController(); // Definir el controlador del mapa

  @override
  void initState() {
    super.initState();
//    _getCurrentLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation(); // Llamar después de que el widget esté completamente renderizado
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
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
          child: Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    });
    // Mover la cámara a la posición inicial
    //mapController.move(_initialPosition!, 18.0);
  }

  void _iniciarRegistro() {
    setState(() {
      _isRecording = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });

    _iniciarSeguimientoUbicacion();
  }

  void _iniciarSeguimientoUbicacion() {
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: LocationSettings(distanceFilter: 10))
        .listen((Position position) {
      final newPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _lastPosition = newPosition;
        _routeCoords.add(newPosition);

        _routePolyline = Polyline(
          points: _routeCoords,
          strokeWidth: 5,
          color: Colors.blue,
        );

        _markers.clear();
        _markers.add(
          Marker(
            point: newPosition,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      });

      // Mover la cámara a la nueva posición
      mapController.move(newPosition, 18.0);
    });
  }

  void _finalizarRegistro() async {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();

    setState(() {
      _isRecording = false;
    });

    // Preparar los datos para enviar al backend
    Map<String, dynamic> rutaData = {
      "puntos": convertirAFormato(_routeCoords),
      "tiempo_segundos": _seconds,
      "distancia_km": _distanceTraveled / 1000,
    };

    // Enviar los datos de la ruta al backend
    int? rutaId = await postRuta(rutaData);
    if (rutaId != null) {
      // Redirigir a la pantalla correspondiente
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RutaFormPage(
            rutaId: rutaId,  // Pasamos el ID de la ruta creada
            distanceTraveled: _distanceTraveled,
            secondsElapsed: _seconds,
            onSave: (rutaData) {
              _updateRuta(
                rutaId,
                rutaData['nombre'],
                rutaData['descripcion'],
                rutaData['dificultad'],
                _distanceTraveled / 1000, // Distancia en km
                _seconds / 3600, // Tiempo en horas
              );
              Navigator.of(context).pop();
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else {
      print('Error al enviar la ruta al backend');
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
            mapController: mapController, // Asignar el controlador al mapa
            options: MapOptions(
              initialCenter: _initialPosition ?? LatLng(0, 0), // Usa initialCenter
              initialZoom: 18.0, // Usa initialZoom
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              PolylineLayer(
                polylines: [_routePolyline],
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          Positioned(
            bottom: 105,
            right: 10,
            child: FloatingActionButton(
              onPressed: () {
                if (_initialPosition != null) {
                  mapController.move(_initialPosition!, 18.0);
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
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
              onPressed: () {
                if (!_isRecording) {
                  _iniciarRegistro();
                } else {
                  _finalizarRegistro();
                }
              },
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
