import 'package:flutter/material.dart';

class ListadoRutasScreen extends StatelessWidget {
  const ListadoRutasScreen({super.key});

  // Lista ficticia de rutas guardadas (puedes reemplazar esto con datos reales)
  final List<Map<String, String>> rutasGuardadas = const [
    {
      'nombre': 'Ruta de la montaña',
      'descripcion': 'Una ruta espectacular por la montaña.',
      'dificultad': 'Difícil',
    },
    {
      'nombre': 'Sendero del río',
      'descripcion': 'Un paseo tranquilo junto al río.',
      'dificultad': 'Fácil',
    },
    {
      'nombre': 'Camino del bosque',
      'descripcion': 'Una ruta intermedia a través del bosque.',
      'dificultad': 'Medio',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Listado de Rutas Guardadas'),
      ),
      body: ListView.builder(
        itemCount: rutasGuardadas.length,
        itemBuilder: (context, index) {
          final ruta = rutasGuardadas[index];

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(ruta['nombre']!),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ruta['descripcion']!),
                  const SizedBox(height: 5),
                  Text('Dificultad: ${ruta['dificultad']}'),
                ],
              ),
              leading: const Icon(Icons.map),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  // Lógica para eliminar la ruta
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ruta ${ruta['nombre']} eliminada')),
                  );
                },
              ),
              onTap: () {
                // Lógica para ver detalles de la ruta
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleRutaScreen(ruta: ruta),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class DetalleRutaScreen extends StatelessWidget {
  final Map<String, String> ruta;

  const DetalleRutaScreen({super.key, required this.ruta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ruta['nombre']!),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ruta['nombre']!,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              ruta['descripcion']!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Dificultad: ${ruta['dificultad']}',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
