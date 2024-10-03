import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pergeo/Pages/mapaRuta.dart';
import 'dart:async'; // Para el uso de Timer

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iTrek',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.green,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
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

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndServices();
  }

  Future<void> _checkPermissionsAndServices() async {
    _locationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_locationServiceEnabled) {
      return;
    }

    _permissionStatus = await Geolocator.checkPermission();
    if (_permissionStatus == LocationPermission.denied) {
      _permissionStatus = await Geolocator.requestPermission();
    }

    if (_permissionStatus == LocationPermission.deniedForever) {
      return;
    }
  }

  void _navigateToMapaRutaScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MapaRutaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50], // Fondo verde pastel
      appBar: AppBar(
        title: const Text('iTrek App', style: TextStyle(fontSize: 28)),
        centerTitle: true,
        backgroundColor: Colors.green[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'iTrek',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/image/image.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Text('No se pudo cargar la imagen: $error');
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Estirar el botón "Iniciar Ruta"
            ElevatedButton(
              onPressed: () => _navigateToMapaRutaScreen(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50C2C9), // Color azul pastel
                padding:
                    const EdgeInsets.symmetric(vertical: 16), // Alto del botón
                textStyle: const TextStyle(fontSize: 20),
                minimumSize:
                    const Size(double.infinity, 50), // Estirar el botón
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(8), // Bordes menos redondeados
                ),
              ),
              child: const Text('Iniciar Ruta'),
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
