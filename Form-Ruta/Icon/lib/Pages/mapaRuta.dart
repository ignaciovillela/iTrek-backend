import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'registroRuta.dart'; // Importa la pantalla RegistroRutaScreen

class MapaRutaScreen extends StatefulWidget {
  const MapaRutaScreen({super.key});

  @override
  _MapaRutaScreenState createState() => _MapaRutaScreenState();
}

class _MapaRutaScreenState extends State<MapaRutaScreen> {
  String _locationMessage = 'Tomando ubicación...';
  double _distanceInKm = 0.0;
  Position? _lastPosition;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  Timer? _timer;
  double? _latitude;
  double? _longitude;
  bool _rutaFinalizada =
      false; // Para controlar la visibilidad del botón "Guardar Ruta"

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _startTimer();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _locationMessage = 'Los servicios de ubicación están deshabilitados.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _locationMessage = 'Permiso de ubicación denegado.';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _locationMessage =
            'Permiso de ubicación denegado permanentemente, no se pueden solicitar permisos.';
      });
      return;
    }

    Geolocator.getPositionStream().listen((Position position) {
      if (_lastPosition != null) {
        _distanceInKm += Geolocator.distanceBetween(
                _lastPosition!.latitude,
                _lastPosition!.longitude,
                position.latitude,
                position.longitude) /
            1000;
      }
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _lastPosition = position;
      });
    });
  }

  void _startTimer() {
    _startTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime = DateTime.now().difference(_startTime!);
      });
    });
  }

  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void _finalizarRuta() {
    _stopTimer();
    setState(() {
      _rutaFinalizada = true; // Mostrar el botón "Guardar Ruta"
    });
  }

  void _guardarRuta() {
    // Navegar a la pantalla de RegistroRutaScreen pasando los datos
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RegistroRutaScreen(
          latitude: _latitude ?? 0.0,
          longitude: _longitude ?? 0.0,
          distance: _distanceInKm,
          timeElapsed:
              '${_elapsedTime.inHours.toString().padLeft(2, '0')}:${(_elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
          // Pasar el callback requerido
          onRutaGuardada: () {
            // Lógica para después de guardar la ruta
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ruta guardada exitosamente.')),
            );
            // Regresar al inicio
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      ),
    );
  }

  void _cancelarRuta() {
    _stopTimer();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Ruta'),
        backgroundColor: Colors.green[300],
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: _rutaFinalizada
                ? 240
                : 180, // Ajustar la posición del container si "Guardar Ruta" se muestra
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latitud: ${_latitude != null ? _latitude!.toStringAsFixed(6) : 'Tomando ubicación...'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Longitud: ${_longitude != null ? _longitude!.toStringAsFixed(6) : 'Tomando ubicación...'}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Km: ${_distanceInKm.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Tiempo: ${_elapsedTime.inHours.toString().padLeft(2, '0')}:${(_elapsedTime.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsedTime.inSeconds % 60).toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Botón Finalizar Ruta
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _finalizarRuta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF50C2C9),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Finalizar Ruta',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16), // Separación entre los botones
                    // Botón Cancelar Ruta
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _cancelarRuta,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC95052),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_rutaFinalizada)
                  SizedBox(
                    width:
                        double.infinity, // Ocupa todo el ancho de la pantalla
                    child: ElevatedButton(
                      onPressed: _guardarRuta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                            0xFF50C9B5), // Color personalizado para Guardar Ruta
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Guardar Ruta',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
