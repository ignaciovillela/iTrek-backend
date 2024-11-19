import 'package:flutter/material.dart';
import 'package:itrek/helpers/widgets.dart';

class RutasCompartidasScreen extends StatefulWidget {
  const RutasCompartidasScreen({super.key});

  @override
  _RutasCompartidasScreenState createState() => _RutasCompartidasScreenState();
}

class _RutasCompartidasScreenState extends State<RutasCompartidasScreen> {
  // Lista de rutas ficticias compartidas por otros usuarios
  final List<Map<String, dynamic>> rutas = [
    {
      'nombre': 'Ruta de la Montaña',
      'descripcion':
          'Una ruta espectacular por la montaña con vistas increíbles.',
      'dificultad': 'Difícil',
      'comentarios': [],
    },
    {
      'nombre': 'Sendero del Río',
      'descripcion': 'Un sendero fácil junto al río, ideal para familias.',
      'dificultad': 'Fácil',
      'comentarios': [],
    },
    {
      'nombre': 'Camino del Bosque',
      'descripcion': 'Una ruta intermedia a través del bosque frondoso.',
      'dificultad': 'Media',
      'comentarios': [],
    },
  ];

  final TextEditingController _comentarioController = TextEditingController();

  // Función para agregar un comentario a una ruta específica
  void _agregarComentario(int index, String comentario) {
    setState(() {
      rutas[index]['comentarios'].add(comentario);
      _comentarioController
          .clear(); // Limpiar el campo después de agregar el comentario
    });
  }

  // Función para seguir una ruta
  void _seguirRuta(String nombreRuta) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Siguiendo la ruta: $nombreRuta')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Rutas de Otras Personas'),
      body: ListView.builder(
        itemCount: rutas.length,
        itemBuilder: (context, index) {
          final ruta = rutas[index];

          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ruta['nombre'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(ruta['descripcion']),
                  const SizedBox(height: 5),
                  Text('Dificultad: ${ruta['dificultad']}'),
                  const SizedBox(height: 10),

                  // Sección de comentarios
                  const Text(
                    'Comentarios:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (ruta['comentarios'].isEmpty)
                    const Text('Aún no hay comentarios.'),
                  for (var comentario in ruta['comentarios'])
                    Text('- $comentario'),
                  const SizedBox(height: 10),

                  // Campo para agregar comentario
                  TextField(
                    controller: _comentarioController,
                    decoration: const InputDecoration(
                      labelText: 'Agregar comentario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botones para agregar comentario y seguir la ruta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_comentarioController.text.isNotEmpty) {
                            _agregarComentario(
                                index, _comentarioController.text);
                          }
                        },
                        child: const Text('Agregar Comentario'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _seguirRuta(ruta['nombre']);
                        },
                        child: const Text('Seguir Ruta'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
