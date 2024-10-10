import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class GoogleMapsPage extends StatefulWidget {
  const GoogleMapsPage({Key? key}) : super(key: key);

  @override
  _GoogleMapsPageState createState() => _GoogleMapsPageState();
}

class _GoogleMapsPageState extends State<GoogleMapsPage> {
  final Map<String, Marker> _markers = {}; // Mapa de marcadores
  GoogleMapController? _mapController; // Controlador del mapa
  final List<LatLng> _routeCoords =
      []; // Lista de coordenadas para el camino recorrido
  Polyline _routePolyline = const Polyline(
    polylineId: PolylineId('route'),
    width: 5,
    color: Colors.blue,
  );
  bool _isRecording = false; // Controlar si el registro está activo o no
  Timer? _timer; // Cronómetro para el tiempo de registro
  Timer? _locationTimer; // Temporizador para simular el movimiento
  int _seconds = 0; // Segundos transcurridos
  double _distanceTraveled = 0.0; // Distancia recorrida en metros
  LatLng? _lastPosition; // Última posición conocida
  LatLng? _initialPosition = const LatLng(
      -12.046374, -77.042793); // Posición inicial simulada (Lima, Perú)

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    // Cancelar los temporizadores cuando el widget se destruye
    _timer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  // Simulación de la ubicación actual
  Future<void> _getCurrentLocation() async {
    setState(() {
      _markers['currentPosition'] = Marker(
        markerId: const MarkerId('currentPosition'),
        position: _initialPosition!,
        infoWindow: const InfoWindow(
          title: 'Posición Actual',
          snippet: 'Simulación de inicio',
        ),
      );
    });
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    if (_initialPosition != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
            _initialPosition!, 18), // Zoom ajustado a 18 para acercar más
      );
    }
  }

  Future<void> _centrarEnPosicionActual() async {
    if (_lastPosition != null) {
      _moverCamara(_lastPosition!);
    }
  }

  void _moverCamara(LatLng nuevaPosicion) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(nuevaPosicion));
  }

  // Iniciar el registro y simular el movimiento
  void _iniciarRegistro() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      // Temporizador para actualizar el tiempo
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _seconds++;
          });
        }
      });

      // Simulación de movimiento, agregando nuevas coordenadas cada 1.5 segundos
      _locationTimer =
          Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (_lastPosition == null) {
          _lastPosition = _initialPosition;
        }

        // Simulamos un pequeño desplazamiento en la latitud y longitud
        LatLng newPosition = LatLng(
          _lastPosition!.latitude + 0.0001,
          _lastPosition!.longitude + 0.0001,
        );

        // Calcular la distancia recorrida
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        _distanceTraveled += distance;

        // Agregar las nuevas coordenadas a la ruta y mover el marcador
        setState(() {
          _routeCoords.add(newPosition);
          _lastPosition = newPosition;

          // Actualizar polilínea
          _routePolyline = Polyline(
            polylineId: const PolylineId('route'),
            points: _routeCoords,
            width: 5,
            color: Colors.blue,
          );

          // Mover marcador a la nueva posición
          _markers['currentPosition'] = Marker(
            markerId: const MarkerId('currentPosition'),
            position: newPosition,
            infoWindow: InfoWindow(
              title: 'Distancia Recorrida',
              snippet: '${(_distanceTraveled / 1000).toStringAsFixed(2)} km',
            ),
          );
        });

        // Mover la cámara al nuevo punto
        _moverCamara(newPosition);
      });
    } else {
      // Detener ambos temporizadores cuando se detiene el registro
      _timer?.cancel();
      _locationTimer?.cancel();
    }
  }

  // Finalizar el registro de la ruta
  void _finalizarRegistro() {
    if (_isRecording) {
      _timer?.cancel();
      _locationTimer?.cancel();
      setState(() {
        _isRecording = false;
      });
    }
  }

  // Enviar la lista de coordenadas al backend
  Future<void> _enviarCoordenadasAlBackend() async {
    print(_routeCoords); // Simulación de envío de coordenadas
  }

  // Función para mostrar el diálogo de confirmación
  void _mostrarConfirmacionFinalizar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Finalizar Ruta'),
          content: const Text('¿Estás seguro de que deseas finalizar la ruta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _finalizarRegistro(); // Finalizar la toma de ruta
                Navigator.of(context).pop(); // Cierra el diálogo
                _enviarCoordenadasAlBackend();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Mostrar distancia en metros y kilómetros
  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(2)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ruta'),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          _initialPosition == null
              ? const Center(
                  child:
                      CircularProgressIndicator()) // Mostrar cargando mientras se obtiene la posición
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition!,
                    zoom: 18, // Zoom más cercano
                  ),
                  markers: _markers.values.toSet(),
                  polylines: {_routePolyline},
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
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              onPressed: _centrarEnPosicionActual,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _isRecording
                  ? _mostrarConfirmacionFinalizar
                  : _iniciarRegistro,
              child: Text(_isRecording ? 'Guardar Ruta' : 'Iniciar Registro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 20), // Tamaño más pequeño
                textStyle: const TextStyle(fontSize: 16), // Fuente más pequeña
              ),
            ),
          ),
        ],
      ),
    );
  }
}
