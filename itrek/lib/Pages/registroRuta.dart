import 'package:flutter/material.dart';

class RegistroRutaScreen extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double distance;
  final String timeElapsed;

  // Recibir los datos de la ruta desde la pantalla anterior
  const RegistroRutaScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.timeElapsed,
  });

  @override
  Widget build(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'iTrek',
              style: TextStyle(
                fontSize: 28, // Texto más pequeño
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10), // Espacio entre el texto y el logo
            Image.asset(
              'assets/images/logo.png', // Asegúrate de tener la imagen logo.png en la carpeta assets/images/
              width: 40, // Tamaño del logo
              height: 40,
            ),
          ],
        ),
        backgroundColor: Colors.green[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // Mostrar los datos de la ruta en un cuadro
                Container(
                  padding: const EdgeInsets.all(16.0),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Latitud: ${latitude.toStringAsFixed(6)}'),
                      const SizedBox(height: 8),
                      Text('Longitud: ${longitude.toStringAsFixed(6)}'),
                      const SizedBox(height: 8),
                      Text('Kilómetros: ${distance.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      Text('Tiempo transcurrido: $timeElapsed'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Campo de texto para el nombre de la ruta
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la Ruta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                // Campo de texto para la descripción de la ruta
                TextField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            // Botón para guardar la ruta en la parte inferior
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width *
                      0.9, // 90% del ancho de la pantalla
                  child: ElevatedButton(
                    onPressed: () {
                      // Mostrar el mensaje y volver a la página de inicio
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ruta registrada exitosamente.'),
                        ),
                      );
                      // Volver a la pantalla de inicio
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF50C9B5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Guardar',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
