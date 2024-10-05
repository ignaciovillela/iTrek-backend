import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

// Nueva página para mostrar el resumen de la ruta
class ResumenRutaPage extends StatelessWidget {
  final int tiempoEnSegundos;
  final double distanciaEnKm;

  const ResumenRutaPage({
    Key? key,
    required this.tiempoEnSegundos,
    required this.distanciaEnKm,
  }) : super(key: key);

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen de la Ruta'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mostrar el tiempo total transcurrido
            Text(
              'Tiempo Total: ${_formatTime(tiempoEnSegundos)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Mostrar la distancia total recorrida
            Text(
              'Distancia Recorrida: ${distanciaEnKm.toStringAsFixed(2)} km',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Botón para regresar a la pantalla anterior
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Volver a la página anterior
              },
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

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
  int _seconds = 0; // Segundos transcurridos
  double _distanceTraveled = 0.0; // Distancia recorrida en metros
  LatLng? _lastPosition; // Última posición conocida

  final LatLng _initialPosition =
      const LatLng(40.7128, -74.0060); // Coordenadas de Nueva York

  @override
  void initState() {
    super.initState();
    _markers['initialPosition'] = Marker(
      markerId: const MarkerId('initialPosition'),
      position: _initialPosition,
      infoWindow: const InfoWindow(
        title: 'Posición Inicial',
        snippet: 'Nueva York',
      ),
    );
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
  }

  Future<void> _centrarEnPosicionActual() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _moverCamara(LatLng(position.latitude, position.longitude));
  }

  void _moverCamara(LatLng nuevaPosicion) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(nuevaPosicion));
  }

  void _iniciarRegistro() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });

      Geolocator.getPositionStream().listen((Position position) {
        LatLng newPosition = LatLng(position.latitude, position.longitude);

        if (_lastPosition != null) {
          _distanceTraveled += Geolocator.distanceBetween(
            _lastPosition!.latitude,
            _lastPosition!.longitude,
            position.latitude,
            position.longitude,
          );
        }

        setState(() {
          _routeCoords.add(newPosition);
          _lastPosition = newPosition;
          _routePolyline = Polyline(
            polylineId: const PolylineId('route'),
            points: _routeCoords,
            width: 5,
            color: Colors.blue,
          );
        });
      });
    } else {
      _timer?.cancel();
    }
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
                Navigator.of(context)
                    .pop(); // Cierra el diálogo, continúa la ruta
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
                // Navegar a la página del resumen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResumenRutaPage(
                      tiempoEnSegundos: _seconds,
                      distanciaEnKm: _distanceTraveled / 1000,
                    ),
                  ),
                );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ruta'),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 12,
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
                Text(
                    'Distancia: ${(_distanceTraveled / 1000).toStringAsFixed(2)} km',
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
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
