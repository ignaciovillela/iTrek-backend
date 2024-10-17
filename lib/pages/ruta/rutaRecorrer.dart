import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart'; // Asegúrate de importar esta dependencia
import 'package:itrek_maps/config.dart';

class RecorrerRutaScreen extends StatefulWidget {
  final Map<String, dynamic> ruta;

  const RecorrerRutaScreen({super.key, required this.ruta});

  @override
  _RecorrerRutaScreenState createState() => _RecorrerRutaScreenState();
}

class _RecorrerRutaScreenState extends State<RecorrerRutaScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  List<LatLng> routePoints = [];
  List<LatLng> userRoutePoints = [];
  bool isLoading = true;
  bool isWalking = false;
  bool isFinished = false; // Nuevo estado para saber si la ruta terminó
  Timer? simulationTimer;
  int simulationIndex = 0;
  double totalDistance = 0.0; // Distancia total recorrida
  Stopwatch stopwatch = Stopwatch(); // Para medir el tiempo de recorrido
  LatLng? _initialPosition; // Para guardar la ubicación inicial

  @override
  void initState() {
    super.initState();
    _fetchRoutePoints(); // Trae los puntos de la ruta
    _getCurrentLocation(); // Obtener la ubicación actual al iniciar
  }

  @override
  void dispose() {
    // Cancelar la simulación si está corriendo
    simulationTimer?.cancel();
    super.dispose();
  }

  // Función para obtener la ubicación actual del dispositivo
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings()
    );
    setState(() {
      _initialPosition = LatLng(position.latitude,
          position.longitude); // Establecer la ubicación inicial
      _markers.add(
        Marker(
          markerId: const MarkerId('currentPosition'), // ID del marcador
          position: _initialPosition!, // Posición del marcador
          infoWindow: const InfoWindow(
            title: 'Posición Actual',
            snippet: 'Ubicación obtenida del dispositivo',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    });

    // Centramos el mapa en la ubicación actual
    _mapController.animateCamera(
      CameraUpdate.newLatLng(_initialPosition!),
    );
    }

  // Función para obtener los puntos de la ruta desde el backend
  Future<void> _fetchRoutePoints() async {
    try {
      final response =
          await http.get(Uri.parse('$BASE_URL/api/rutas/${widget.ruta['id']}'));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['puntos'] != null &&
            jsonResponse['puntos'].isNotEmpty) {
          List<dynamic> puntos = jsonResponse['puntos'];

          setState(() {
            routePoints = puntos.map((punto) {
              return LatLng(punto['latitud'], punto['longitud']);
            }).toList();

            _initMarkersAndPolylines();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('No se encontraron puntos en la ruta')),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Error al cargar los puntos de la ruta: ${response.body}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e')),
      );
    }
  }

  // Inicializar marcadores y polilíneas en el mapa
  void _initMarkersAndPolylines() {
    if (routePoints.isNotEmpty) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: routePoints.first,
          infoWindow: const InfoWindow(title: 'Inicio de la Ruta'),
        ),
      );

      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: routePoints.last,
          infoWindow: const InfoWindow(title: 'Fin de la Ruta'),
        ),
      );

      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: Colors.blue,
          width: 5,
        ),
      );
    }
  }

  // Función para iniciar la simulación de la ruta
  void _startWalking() {
    setState(() {
      isWalking = true;
      simulationIndex = 0;
      userRoutePoints = [];
      totalDistance = 0.0; // Reiniciar distancia
      stopwatch.start(); // Iniciar el cronómetro
      isFinished = false; // Resetear el estado de finalización
    });

    // Iniciar la simulación del recorrido punto por punto (más lenta: 5 segundos)
    simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (simulationIndex < routePoints.length) {
        setState(() {
          // Agregar punto al recorrido del usuario
          LatLng currentPoint = routePoints[simulationIndex];
          userRoutePoints.add(currentPoint);

          // Dibujar la ruta simulada en verde
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('user_route'),
              points: userRoutePoints,
              color: Colors.green, // Línea verde para la ruta recorrida
              width: 5,
            ),
          );

          // Actualizar la distancia recorrida
          if (userRoutePoints.length > 1) {
            totalDistance += _calculateDistance(
              userRoutePoints[userRoutePoints.length - 2],
              userRoutePoints.last,
            );
          }

          // Mover la cámara a la nueva posición simulada
          _mapController.animateCamera(
            CameraUpdate.newLatLng(currentPoint),
          );

          // Actualizar el marcador de la posición actual en azul
          _markers.removeWhere(
              (m) => m.markerId == const MarkerId('currentPosition'));
          _markers.add(
            Marker(
              markerId: const MarkerId('currentPosition'),
              position: currentPoint,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
              infoWindow: const InfoWindow(title: 'Posición Actual'),
            ),
          );

          simulationIndex++;
        });
      } else {
        timer.cancel(); // Detener la simulación cuando se complete la ruta
        stopwatch.stop(); // Detener el cronómetro
        setState(() {
          isFinished = true; // La ruta ha terminado
        });
      }
    });
  }

  // Función para calcular la distancia entre dos puntos (en km) usando la fórmula de Haversine
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLng = _degreesToRadians(end.longitude - start.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Función para terminar la simulación de la ruta
  void _endWalking() {
    setState(() {
      isWalking = false;
    });
    simulationTimer?.cancel();
    stopwatch.stop(); // Detener el cronómetro
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ruta finalizada')),
    );
  }

  // Función para volver al listado de rutas
  void _volverListadoRutas() {
    Navigator.pop(context); // Volver a la pantalla anterior (listado de rutas)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recorriendo: ${widget.ruta['nombre']}'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: routePoints.isNotEmpty
                        ? routePoints.first
                        : (_initialPosition ??
                            const LatLng(0,
                                0)), // Asegurarse de que hay coordenadas válidas
                    zoom: 18.0,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_initialPosition != null) {
                      _mapController.animateCamera(
                        CameraUpdate.newLatLng(_initialPosition!),
                      );
                    }
                  },
                ),
                // Mostrar tiempo y distancia en la pantalla
                if (isWalking || isFinished)
                  Positioned(
                    top: 20,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiempo: ${stopwatch.elapsed.inMinutes}:${(stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Distancia: ${totalDistance.toStringAsFixed(2)} km',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                // Botón para iniciar, terminar o volver al listado
                Positioned(
                  left: 20,
                  right: 60,
                  bottom: 30,
                  child: ElevatedButton(
                    onPressed: isFinished
                        ? _volverListadoRutas
                        : (isWalking ? _endWalking : _startWalking),
                    child: Text(isFinished
                        ? 'Volver al listado de rutas'
                        : (isWalking ? 'Terminar Ruta' : 'Iniciar Ruta')),
                  ),
                ),
              ],
            ),
    );
  }
}
