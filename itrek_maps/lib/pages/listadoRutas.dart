import 'package:flutter/material.dart';
import 'inicio.dart'; // Importar la pantalla del menú

class ListadoRutasScreen extends StatelessWidget {
  const ListadoRutasScreen({super.key});

  // Lista ficticia de rutas guardadas
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
        backgroundColor: const Color(0xFF50C9B5), // Color de la appBar
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Asegúrate de que el logo esté en la carpeta assets
              height: 30, // Tamaño pequeño del logo
            ),
            const SizedBox(width: 10), // Espacio entre el logo y el texto
            const Text('Listado de Rutas'),
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: rutasGuardadas.length,
        itemBuilder: (context, index) {
          final ruta = rutasGuardadas[index];

          return Card(
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
            child: ListTile(
              title: Text(
                ruta['nombre']!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ruta['descripcion']!),
                  const SizedBox(height: 5),
                  Text('Dificultad: ${ruta['dificultad']}'),
                ],
              ),
              leading: const Icon(Icons.map, color: Color(0xFF50C9B5)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
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

class DetalleRutaScreen extends StatefulWidget {
  final Map<String, String> ruta;

  const DetalleRutaScreen({super.key, required this.ruta});

  @override
  _DetalleRutaScreenState createState() => _DetalleRutaScreenState();
}

class _DetalleRutaScreenState extends State<DetalleRutaScreen> {
  bool _isEditing = false; // Controla si se está editando o no
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.ruta['nombre']);
    _descripcionController =
        TextEditingController(text: widget.ruta['descripcion']);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navegar a MenuScreen en lugar de regresar al listado de rutas
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MenuScreen()),
            );
          },
        ),
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Asegúrate de que el logo esté en la carpeta assets
              height: 30, // Tamaño pequeño del logo
            ),
            const SizedBox(width: 10), // Espacio entre el logo y el texto
            Text(widget.ruta['nombre']!),
          ],
        ),
        backgroundColor: const Color(0xFF50C9B5),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing; // Cambiar entre modo edición y vista
                if (!_isEditing) {
                  // Guardar cambios
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cambios guardados')),
                  );
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(labelText: 'Nombre de la Ruta'),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              enabled: _isEditing, // Solo editable en modo edición
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              style: const TextStyle(fontSize: 16),
              enabled: _isEditing, // Solo editable en modo edición
            ),
            const SizedBox(height: 10),
            Text(
              'Dificultad: ${widget.ruta['dificultad']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Botón de "Volver" en la parte inferior
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFC95052), // Color rojo para el botón
                minimumSize: const Size(double.infinity, 50), // Botón ancho
              ),
              onPressed: () {
                // Navegar a MenuScreen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MenuScreen()),
                );
              },
              child: const Text(
                'Volver',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
