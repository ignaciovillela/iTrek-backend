import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:itrek/map.dart';
import 'package:itrek/request.dart';
import 'package:latlong2/latlong.dart';

// Pantalla para recorrer una ruta específica
class RecorrerRutaScreen extends StatefulWidget {
  final Map<String, dynamic> ruta; // Mapa con los detalles de la ruta

  const RecorrerRutaScreen({super.key, required this.ruta});

  @override
  _RecorrerRutaScreenState createState() => _RecorrerRutaScreenState();
}

// Estado de la pantalla para gestionar la lógica y el estado de la ruta
class _RecorrerRutaScreenState extends State<RecorrerRutaScreen> {
  final MapController _mapController = MapController(); // Controlador del mapa
  final List<Marker> _markers = []; // Lista de marcadores en el mapa
  final List<Polyline> _polylines = []; // Lista de polígonos en el mapa para dibujar la ruta
  List<LatLng> routePoints = []; // Puntos de la ruta cargados desde el backend
  List<LatLng> userRoutePoints = []; // Puntos de la ruta recorridos por el usuario
  bool isLoading = true; // Indica si los datos están cargando
  bool isWalking = false; // Indica si el usuario está recorriendo la ruta
  bool isFinished = false; // Indica si el recorrido ha finalizado
  Timer? simulationTimer; // Temporizador para simular el recorrido
  int simulationIndex = 0; // Índice actual en la simulación de la ruta
  double totalDistance = 0.0; // Distancia total recorrida
  Stopwatch stopwatch = Stopwatch(); // Cronómetro para el tiempo del recorrido
  LatLng? _initialPosition; // Posición inicial del usuario

  @override
  void initState() {
    super.initState();
    _fetchRoutePoints(); // Carga los puntos de la ruta
    _getCurrentLocation(); // Obtiene la ubicación actual del usuario
  }

  @override
  void dispose() {
    simulationTimer?.cancel(); // Cancela el temporizador al eliminar la pantalla
    super.dispose();
  }

  // Obtiene la ubicación actual del usuario
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(locationSettings: AndroidSettings());
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude); // Guarda la ubicación inicial
      _markers.add(
        Marker(
          point: _initialPosition!,
          child: Icon(Icons.location_on, color: Colors.blue), // Marca la posición actual en el mapa
        ),
      );
      _mapController.move(_initialPosition!, 18.0); // Mueve la cámara del mapa a la posición inicial
    });
  }

  // Obtiene los puntos de la ruta desde el backend
  Future<void> _fetchRoutePoints() async {
    setState(() {
      isLoading = true;
    });

    await makeRequest(
      method: GET,
      url: ROUTE_DETAIL,
      urlVars: {'id': widget.ruta['id']},
      onOk: (response) {
        final jsonResponse = jsonDecode(response.body); // Decodifica la respuesta JSON

        if (jsonResponse['puntos'] != null && jsonResponse['puntos'].isNotEmpty) {
          List<dynamic> puntos = jsonResponse['puntos'];

          setState(() {
            routePoints = puntos.map((punto) {
              return LatLng(punto['latitud'], punto['longitud']); // Convierte cada punto en LatLng
            }).toList();

            _initMarkersAndPolylines(); // Inicializa los marcadores y líneas de la ruta
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se encontraron puntos en la ruta')),
          );
        }
      },
      onError: (response) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los puntos de la ruta: ${response.body}')),
        );
      },
      onConnectionError: (errorMessage) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );
  }

  // Inicializa los marcadores en los puntos de inicio y fin y dibuja la ruta
  void _initMarkersAndPolylines() {
    if (routePoints.isNotEmpty) {
      _markers.add(
        Marker(
          point: routePoints.first,
          child: Icon(Icons.flag, color: Colors.green), // Marca el punto de inicio
        ),
      );
      _markers.add(
        Marker(
          point: routePoints.last,
          child: Icon(Icons.flag, color: Colors.red), // Marca el punto final
        ),
      );
      _polylines.add(
        Polyline(
          points: routePoints, // Dibuja la ruta con los puntos obtenidos
          color: Colors.blue,
          strokeWidth: 4.0,
        ),
      );
    }
  }

  // Inicia la simulación del recorrido de la ruta
  void _startWalking() {
    setState(() {
      isWalking = true;
      simulationIndex = 0;
      userRoutePoints = [];
      totalDistance = 0.0;
      stopwatch.start(); // Inicia el cronómetro para medir el tiempo
      isFinished = false;
    });

    // Temporizador para simular el avance en la ruta cada 5 segundos
    simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (simulationIndex < routePoints.length) {
        setState(() {
          LatLng currentPoint = routePoints[simulationIndex];
          userRoutePoints.add(currentPoint); // Agrega el punto actual a la lista del usuario

          _polylines.add(
            Polyline(
              points: userRoutePoints, // Dibuja la línea de la ruta recorrida por el usuario
              color: Colors.green,
              strokeWidth: 4.0,
            ),
          );

          // Calcula la distancia total recorrida
          if (userRoutePoints.length > 1) {
            totalDistance += _calculateDistance(
              userRoutePoints[userRoutePoints.length - 2],
              userRoutePoints.last,
            );
          }

          _mapController.move(currentPoint, 18.0); // Mueve la cámara al punto actual

          simulationIndex++; // Avanza al siguiente punto de la ruta
        });
      } else {
        timer.cancel(); // Detiene el temporizador al finalizar la ruta
        stopwatch.stop(); // Detiene el cronómetro
        setState(() {
          isFinished = true;
        });
      }
    });
  }

  // Calcula la distancia entre dos puntos (en kilómetros)
  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371; // Radio de la Tierra en kilómetros
    double dLat = _degreesToRadians(end.latitude - start.latitude);
    double dLng = _degreesToRadians(end.longitude - start.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(start.latitude)) *
            cos(_degreesToRadians(end.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c; // Distancia en kilómetros
  }

  // Convierte grados a radianes para cálculos trigonométricos
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Finaliza la simulación del recorrido
  void _endWalking() {
    setState(() {
      isWalking = false;
    });
    simulationTimer?.cancel(); // Cancela el temporizador
    stopwatch.stop(); // Detiene el cronómetro
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ruta finalizada')),
    );
  }

  // Vuelve al listado de rutas
  void _volverListadoRutas() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recorriendo: ${widget.ruta['nombre']}'), // Título con el nombre de la ruta
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Indicador de carga
          : Stack(
        children: [
          // Mapa de la ruta
          buildMap(
            mapController: _mapController,
            initialPosition: routePoints.isNotEmpty ? routePoints.first : _initialPosition ?? LatLng(0, 0),
            routePolylines: _polylines,
            markers: _markers,
          ),
          // Muestra el tiempo y distancia recorridos si está caminando o ha terminado
          if (isWalking || isFinished)
            Positioned(
              top: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiempo: ${stopwatch.elapsed.inMinutes}:${(stopwatch.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Distancia: ${totalDistance.toStringAsFixed(2)} km',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          // Botón para iniciar/terminar la ruta o volver al listado
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
