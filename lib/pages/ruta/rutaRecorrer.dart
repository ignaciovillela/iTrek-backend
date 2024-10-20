import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:itrek/config.dart';
import 'package:itrek/request/request.dart';
import 'package:latlong2/latlong.dart';

class RecorrerRutaScreen extends StatefulWidget {
  final Map<String, dynamic> ruta;

  const RecorrerRutaScreen({super.key, required this.ruta});

  @override
  _RecorrerRutaScreenState createState() => _RecorrerRutaScreenState();
}

class _RecorrerRutaScreenState extends State<RecorrerRutaScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];
  List<LatLng> routePoints = [];
  List<LatLng> userRoutePoints = [];
  bool isLoading = true;
  bool isWalking = false;
  bool isFinished = false;
  Timer? simulationTimer;
  int simulationIndex = 0;
  double totalDistance = 0.0;
  Stopwatch stopwatch = Stopwatch();
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _fetchRoutePoints();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(locationSettings: AndroidSettings());
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          point: _initialPosition!,
          child: Icon(Icons.location_on, color: Colors.blue),
        ),
      );
      _mapController.move(_initialPosition!, 18.0); // Mueve la cámara en flutter_map
    });
  }

  Future<void> _fetchRoutePoints() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await makeRequest(
        method: 'GET',
        url: '$BASE_URL/api/rutas/${widget.ruta['id']}',
        useToken: true, // Se asume que se necesita token
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['puntos'] != null && jsonResponse['puntos'].isNotEmpty) {
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
            const SnackBar(content: Text('No se encontraron puntos en la ruta')),
          );
        }
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los puntos de la ruta: ${response.body}')),
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

  void _initMarkersAndPolylines() {
    if (routePoints.isNotEmpty) {
      _markers.add(
        Marker(
          point: routePoints.first,
          child: Icon(Icons.flag, color: Colors.green),
        ),
      );
      _markers.add(
        Marker(
          point: routePoints.last,
          child: Icon(Icons.flag, color: Colors.red),
        ),
      );
      _polylines.add(
        Polyline(
          points: routePoints,
          color: Colors.blue,
          strokeWidth: 4.0,
        ),
      );
    }
  }

  void _startWalking() {
    setState(() {
      isWalking = true;
      simulationIndex = 0;
      userRoutePoints = [];
      totalDistance = 0.0;
      stopwatch.start();
      isFinished = false;
    });

    simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (simulationIndex < routePoints.length) {
        setState(() {
          LatLng currentPoint = routePoints[simulationIndex];
          userRoutePoints.add(currentPoint);

          _polylines.add(
            Polyline(
              points: userRoutePoints,
              color: Colors.green,
              strokeWidth: 4.0,
            ),
          );

          if (userRoutePoints.length > 1) {
            totalDistance += _calculateDistance(
              userRoutePoints[userRoutePoints.length - 2],
              userRoutePoints.last,
            );
          }

          _mapController.move(currentPoint, 18.0);

          simulationIndex++;
        });
      } else {
        timer.cancel();
        stopwatch.stop();
        setState(() {
          isFinished = true;
        });
      }
    });
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371;
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

  void _endWalking() {
    setState(() {
      isWalking = false;
    });
    simulationTimer?.cancel();
    stopwatch.stop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ruta finalizada')),
    );
  }

  void _volverListadoRutas() {
    Navigator.pop(context);
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
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: routePoints.isNotEmpty ? routePoints.first : _initialPosition ?? LatLng(0, 0),
              initialZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              PolylineLayer(
                polylines: _polylines,
              ),
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
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
