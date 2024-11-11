import 'dart:convert'; // Importa la biblioteca para trabajar con JSON.

import 'package:flutter/material.dart'; // Importa el paquete de Flutter para crear interfaces de usuario.
import 'package:flutter_map/flutter_map.dart'; // Importa el paquete para trabajar con mapas en Flutter.
import 'package:itrek/db.dart'; // Importa el helper de base de datos.
import 'package:itrek/img.dart'; // Importa recursos de imagen.
import 'package:itrek/map.dart'; // Importa funciones relacionadas con la visualización de mapas.
import 'package:itrek/pages/route/route_walk.dart'; // Importa la pantalla para recorrer rutas.
import 'package:itrek/request.dart'; // Importa funciones para realizar solicitudes HTTP.
import 'package:latlong2/latlong.dart'; // Importa el paquete para trabajar con coordenadas geográficas.

// Pantalla principal que muestra el listado de rutas guardadas.

// Pantalla para ver y editar los detalles de una ruta.
class DetalleRutaScreen extends StatefulWidget {
  final Map<String, dynamic> ruta;

  const DetalleRutaScreen({super.key, required this.ruta});

  @override
  _DetalleRutaScreenState createState() => _DetalleRutaScreenState();
}

// Estado que gestiona la pantalla DetalleRutaScreen.
class _DetalleRutaScreenState extends State<DetalleRutaScreen> {
  bool _isEditing = false; // Modo de edición habilitado/deshabilitado.
  late TextEditingController _nombreController; // Controlador para el campo de nombre.
  late TextEditingController _descripcionController; // Controlador para el campo de descripción.
  String? localUsername; // Username almacenado localmente.
  bool esPropietario = false; // Indica si el usuario es el propietario de la ruta.
  List<dynamic>? usuariosFiltrados; // Lista de usuarios obtenidos en la búsqueda.
  TextEditingController _searchController = TextEditingController(); // Controlador de búsqueda.
  String? errorMessage; // Variable para mensajes de error de búsqueda.
  late MapController _mapController; // Controlador para el mapa.
  List<LatLng> routePoints = []; // Puntos de la ruta.

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.ruta['nombre']); // Inicializa el controlador de nombre.
    _descripcionController = TextEditingController(text: widget.ruta['descripcion']); // Inicializa el controlador de descripción.
    _fetchLocalUsername(); // Obtiene el username almacenado localmente.
    _mapController = MapController(); // Inicializa el controlador del mapa.
    _fetchRoutePoints(); // Llama a _fetchRoutePoints para cargar los puntos de la ruta.
  }

  @override
  void dispose() {
    _nombreController.dispose(); // Libera el controlador de nombre.
    _descripcionController.dispose(); // Libera el controlador de descripción.
    _searchController.dispose(); // Libera el controlador de búsqueda.
    super.dispose();
  }

  // Obtiene el username almacenado localmente.
  Future<void> _fetchLocalUsername() async {
    final username = await db.values.get(db.values.username);
    setState(() {
      localUsername = username as String?; // Almacena el username.
      esPropietario = (localUsername == widget.ruta['usuario']['username']); // Verifica si es propietario.
    });
  }

  // Obtiene los puntos de la ruta desde el backend.
  Future<List<LatLng>> _fetchRoutePoints() async {
    final List<LatLng> points = []; // Lista para almacenar los puntos

    await makeRequest(
      method: GET,
      url: ROUTE_DETAIL,
      urlVars: {'id': widget.ruta['id']}, // Llama al backend con el ID de la ruta.
      onOk: (response) {
        final jsonResponse = jsonDecode(response.body); // Decodifica la respuesta JSON.
        if (jsonResponse['puntos'] != null && jsonResponse['puntos'].isNotEmpty) {
          points.addAll(
            jsonResponse['puntos'].map<LatLng>((punto) => LatLng(punto['latitud'], punto['longitud'])),
          ); // Convierte cada punto en LatLng y lo agrega a la lista
        }
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar los puntos de la ruta: ${response.body}')),
        );
      },
      onConnectionError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );

    return points; // Retorna la lista de puntos
  }

  // Muestra el modal con la lista de usuarios para compartir la ruta.
  void _showUsuariosBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (text) async {
                            await _fetchUsuarios();
                            setModalState(() {}); // Actualiza el estado del modal.
                          },
                          decoration: InputDecoration(
                            labelText: 'Buscar usuario',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.search),
                        onPressed: () async {
                          await _fetchUsuarios();
                          setModalState(() {}); // Actualiza el estado del modal.
                        },
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null) // Muestra un mensaje de error.
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: usuariosFiltrados == null
                      ? const Center(child: Text("Ingrese un término para buscar usuarios"))
                      : usuariosFiltrados!.isEmpty
                      ? const Center(child: Text("No se encontraron usuarios"))
                      : ListView.builder(
                    itemCount: usuariosFiltrados!.length,
                    itemBuilder: (context, index) {
                      final usuario = usuariosFiltrados![index];

                      return ListTile(
                        title: Text(usuario['username']),
                        onTap: () {
                          Navigator.pop(context); // Cierra el modal.
                          _compartirRutaConUsuario(usuario['id']); // Comparte la ruta.
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Realiza la búsqueda de usuarios en el backend.
  Future<void> _fetchUsuarios() async {
    String query = _searchController.text.trim();

    if (query == '') {
      setState(() {
        errorMessage = '';
        usuariosFiltrados = null;
      });
      return;
    }

    await makeRequest(
      method: GET,
      url: SEARCH_USER,
      urlVars: {'query': query}, // Envia la consulta al backend.
      onOk: (response) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          usuariosFiltrados = data;
          errorMessage = null; // Limpia el mensaje de error si la búsqueda es exitosa.
        });
      },
      onError: (response) {
        var errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['error'];
          usuariosFiltrados = null; // Limpia la lista si hay un error.
        });
      },
      onConnectionError: (errorMessage) {
        setState(() {
          this.errorMessage = 'Error de conexión: $errorMessage';
          usuariosFiltrados = [];
        });
      },
    );
  }

  // Comparte la ruta con un usuario específico en el backend.
  Future<void> _compartirRutaConUsuario(int usuarioId) async {
    await makeRequest(
      method: POST,
      url: ROUTE_SHARE,
      urlVars: {'id':widget.ruta['id'],'usuarioId': usuarioId}, // Comparte la ruta con el usuario.
      onOk: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ruta compartida exitosamente con el usuario $usuarioId')),
        );
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al compartir la ruta: Código ${response.statusCode}')),
        );
      },
      onConnectionError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            logoWhite,
            const SizedBox(width: 10),
            const Text("iTrek Editar Ruta"),
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
              enabled: _isEditing, // Campo solo editable en modo edición.
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              style: const TextStyle(fontSize: 16),
              enabled: _isEditing, // Campo solo editable en modo edición.
            ),
            const SizedBox(height: 10),
            Text(
              'Dificultad: ${widget.ruta['dificultad']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Distancia: ${widget.ruta['distancia_km']} km', // Distancia en km.
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Tiempo estimado: ${widget.ruta['tiempo_estimado_horas']} horas', // Tiempo estimado.
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            // Sección para mostrar el mapa en un cuadro.
            SizedBox(
              height: 350, // Ajusta la altura para mejorar la visualización del mapa.
              child: FutureBuilder<List<LatLng>>(
                future: _fetchRoutePoints(), // Obtiene los puntos de la ruta.
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator()); // Muestra un indicador de carga.
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}')); // Muestra un error si ocurre.
                  } else {
                    final routePoints = snapshot.data ?? []; // Obtiene los puntos de la ruta.
                    final result = getCenterAndZoomForBounds(routePoints);
                    final LatLng center = result['center'];
                    final double zoom = result['zoom'];
                    return buildMap(
                      mapController: _mapController,
                      initialPosition: center,
                      initialZoom: zoom,
                      routePolylines: [
                        Polyline(
                          pattern: StrokePattern.dashed(segments: [5, 6]),
                          points: routePoints, // Genera la lista de puntos para la polilínea.
                          color: Colors.orange, // Color de la ruta.
                          borderStrokeWidth: 1.5,
                          borderColor: Colors.red,
                          strokeWidth: 3.0, // Grosor de la línea de la ruta.
                        ),
                      ],
                      markers: [
                        if (routePoints.isNotEmpty)
                          Marker(
                            point: routePoints.first,
                            width: 80, // Añade un ancho al marcador.
                            height: 80, // Añade una altura al marcador.
                            child: const Icon(Icons.flag, color: Colors.green), // Icono verde para el inicio.
                          ),
                        if (routePoints.isNotEmpty)
                          Marker(
                            point: routePoints.last,
                            width: 80, // Añade un ancho al marcador.
                            height: 80, // Añade una altura al marcador.
                            child: const Icon(Icons.flag, color: Colors.red), // Icono rojo para el final.
                          ),
                      ],
                    );
                  }
                },
              ),
            ),

            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF50C9B5),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                setState(() {
                  _isEditing = !_isEditing; // Alterna entre editar y guardar.
                });
              },
              child: Text(
                _isEditing ? 'Guardar' : 'Editar',
                style: const TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                minimumSize: const Size(double.infinity, 50),
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
            const SizedBox(height: 10),
            if (esPropietario) // Solo muestra el botón si el usuario es el propietario.
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  _showUsuariosBottomSheet(); // Muestra el modal para compartir.
                },
                child: const Text(
                  'Compartir Ruta',
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
