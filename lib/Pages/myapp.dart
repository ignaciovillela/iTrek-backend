import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async'; // Para el uso de Timer
import 'map.dart'; // Importa la pantalla de MapaRuta

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
        title: const Text('Iniciar Ruta', style: TextStyle(fontSize: 28)),
        centerTitle: true,
        backgroundColor: Colors.green[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Para alinear a la izquierda
          children: [
            Row(
              children: [
                const Text(
                  'iTrek',
                  style: TextStyle(
                      fontSize: 28, // Texto más pequeño
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                const SizedBox(width: 10), // Espacio entre el texto y el logo
                Image.asset(
                  'assets/images/logo.png', // Asegúrate de tener la imagen logo.png en la carpeta assets/images/
                  width: 50, // Tamaño del logo
                  height: 50,
                ),
              ],
            ),
            const SizedBox(
                height: 60), // Espacio extra entre el encabezado y el botón
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/images/image.png',
                  width: 200,
                  height: 200,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('No se pudo cargar la imagen');
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Botón Iniciar Ruta más grande, centrado y con color personalizado
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width *
                    0.8, // Botón más largo (80% del ancho de la pantalla)
                child: ElevatedButton(
                  onPressed: () => _navigateToMapaRutaScreen(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF50C2C9), // Color personalizado
                    padding: const EdgeInsets.symmetric(
                        vertical: 20), // Altura del botón
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Bordes menos redondeados
                    ),
                    textStyle: const TextStyle(
                        fontSize: 22,
                        color: Colors.white), // Color de texto blanco
                  ),
                  child: const Text('Comenzar Ruta'),
                ),
              ),
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
