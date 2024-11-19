import 'package:flutter/material.dart';
import 'package:itrek/helpers/widgets.dart';

// Esta es la nueva página que mostrará los valores de tiempo y kilómetros
class ResumenRutaPage extends StatelessWidget {
  final int tiempoEnSegundos; // El tiempo total en segundos
  final double distanciaEnKm; // La distancia total en kilómetros

  // Constructor que recibe el tiempo y la distancia
  const ResumenRutaPage({
    super.key,
    required this.tiempoEnSegundos,
    required this.distanciaEnKm,
  });

  // Función para formatear el tiempo en formato HH:MM:SS
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Resumen de la Ruta'),
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
