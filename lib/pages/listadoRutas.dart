import 'package:flutter/material.dart';
import 'dart:convert'; // Para manejar JSON
import 'package:http/http.dart' as http;
import 'inicio.dart'; // Importar la pantalla del menú
import 'recorrerRuta.dart'; // Nueva pantalla para recorrer la ruta

const baseUrl = 'http://10.20.4.151:8000';

class ListadoRutasScreen extends StatefulWidget {
  const ListadoRutasScreen({super.key});

  @override
  _ListadoRutasScreenState createState() => _ListadoRutasScreenState();
}

class _ListadoRutasScreenState extends State<ListadoRutasScreen> {
  List<dynamic> rutasGuardadas = [];

  @override
  void initState() {
    super.initState();
    _fetchRutas(); // Llamar a la API cuando se inicializa el widget
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchRutas(); // Llamar a la API cada vez que se muestra la pantalla
  }

  Future<void> _fetchRutas() async {
    final response = await http.get(Uri.parse('$baseUrl/api/rutas/'));

    if (response.statusCode == 200) {
      setState(() {
        // Asegurarse de que los textos se manejen con la codificación correcta
        rutasGuardadas = jsonDecode(utf8.decode(response.bodyBytes));
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar las rutas')),
      );
    }
  }

  Future<void> _deleteRuta(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/api/rutas/$id/'));

    if (response.statusCode == 204) {
      setState(() {
        rutasGuardadas.removeWhere((ruta) => ruta['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta eliminada con éxito')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al eliminar la ruta')),
      );
    }
  }

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
      body: rutasGuardadas.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
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
                      ruta['nombre'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ruta['descripcion']),
                        const SizedBox(height: 5),
                        Text('Dificultad: ${ruta['dificultad']}'),
                      ],
                    ),
                    leading: const Icon(Icons.map, color: Color(0xFF50C9B5)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteRuta(ruta['id']);
                      },
                    ),
                    onTap: () async {
                      // Esperamos el resultado de la pantalla de detalles
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetalleRutaScreen(ruta: ruta),
                        ),
                      );

                      // Si result es true, recargamos las rutas
                      if (result == true) {
                        _fetchRutas();
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

class DetalleRutaScreen extends StatefulWidget {
  final Map<String, dynamic> ruta;

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

  Future<void> _updateRuta(int id) async {
    // Crear el cuerpo de la solicitud
    final response = await http.patch(
      Uri.parse('$baseUrl/api/rutas/$id/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'nombre': _nombreController.text, // Actualizamos el nombre
        'descripcion':
            _descripcionController.text, // Actualizamos la descripción
        'dificultad':
            widget.ruta['dificultad'], // Asegúrate de que el valor sea correcto
        'distancia_km': widget.ruta['distancia_km'], // Distancia en km
        'tiempo_estimado_horas':
            widget.ruta['tiempo_estimado_horas'], // Tiempo estimado en horas
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ruta actualizada con éxito')),
      );
      Navigator.pop(context, true); // Aquí retornamos true
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error al actualizar la ruta: ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Asegúrate de que el logo esté en la carpeta assets
              height: 30, // Tamaño pequeño del logo
            ),
            const SizedBox(width: 10), // Espacio entre el logo y el texto
            Text("iTrek Editar Ruta"),
          ],
        ),
        backgroundColor: const Color(0xFF50C9B5),
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
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50C9B5), // Color verde
                minimumSize: const Size(double.infinity, 50), // Botón ancho
              ),
              onPressed: () {
                setState(() {
                  if (_isEditing) {
                    _updateRuta(widget.ruta['id']); // Guardar cambios
                  }
                  _isEditing = !_isEditing; // Cambiar entre editar y guardar
                });
              },
              child: Text(_isEditing ? 'Guardar' : 'Editar',
                  style: const TextStyle(color: Colors.white, fontSize: 16.0)),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Botón azul para "Recorrer Ruta"
                minimumSize: const Size(double.infinity, 50), // Botón ancho
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecorrerRutaScreen(
                      ruta: widget.ruta,
                    ),
                  ),
                );
              },
              child: const Text(
                'Recorrer Ruta',
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
