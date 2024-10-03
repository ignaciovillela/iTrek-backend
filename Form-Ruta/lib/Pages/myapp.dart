import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Para el uso de Timer

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iTrek',
      theme: ThemeData(
        brightness: Brightness.light, // Cambiado a tema claro
        primarySwatch: Colors.green, // Verde como color principal
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  LocationPermission? _permissionStatus;
  bool _locationServiceEnabled = false;
  String? _location;
  Timer? _locationTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndServices();
  }

  // Verifica el estado de los permisos y si los servicios de ubicación están habilitados
  Future<void> _checkPermissionsAndServices() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      setState(() {
        _location = 'Los servicios de ubicación están deshabilitados.';
      });
      return;
    }

    _permissionStatus = await Geolocator.checkPermission();
    if (_permissionStatus == LocationPermission.denied) {
      _permissionStatus = await Geolocator.requestPermission();
    }

    if (_permissionStatus == LocationPermission.deniedForever) {
      setState(() {
        _location =
            'Permisos de ubicación permanentemente denegados, no se pueden solicitar.';
      });
    }
  }

  // Inicia la toma continua de ubicación
  void _startLocationUpdates() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _getCurrentLocation();
    });
  }

  // Detiene la toma de ubicación
  void _stopLocationUpdates() {
    if (_locationTimer != null) {
      _locationTimer!.cancel();
      setState(() {
        _location = 'Toma de ubicación finalizada';
      });
    }
  }

  // Obtiene la posición actual
  Future<void> _getCurrentLocation() async {
    if (!_locationServiceEnabled) {
      setState(() {
        _location = 'Los servicios de ubicación están deshabilitados.';
      });
      return;
    }

    if (_permissionStatus == LocationPermission.denied ||
        _permissionStatus == LocationPermission.deniedForever) {
      setState(() {
        _location =
            'No se puede obtener la ubicación debido a la falta de permisos.';
      });
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _location =
            'Latitud: ${position.latitude}, Longitud: ${position.longitude}';
      });
    } catch (e) {
      setState(() {
        _location = 'Error obteniendo ubicación: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Geolocator - iTrek app'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _startLocationUpdates,
              child: const Text('Iniciar Toma de Ubicación'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _stopLocationUpdates,
              child: const Text('Finalizar Toma de Ubicación'),
            ),
            const SizedBox(height: 20),
            if (_location != null)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green[100], // Fondo verde suave por defecto
                  borderRadius: BorderRadius.circular(12), // Bordes redondeados
                ),
                child: Text(_location!),
              ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
