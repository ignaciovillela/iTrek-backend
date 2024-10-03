import 'package:flutter/material.dart';

class MapaRutaScreen extends StatelessWidget {
  const MapaRutaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Ruta'),
        backgroundColor: Colors.green[300],
      ),
      body: const Center(
        child: Text(
          '¡Bienvenido a la pantalla del Mapa de Ruta!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
