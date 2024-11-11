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
class ListadoRutasScreen extends StatefulWidget {
  const ListadoRutasScreen({super.key}); // Constructor del widget.

  @override
  _ListadoRutasScreenState createState() => _ListadoRutasScreenState(); // Crea el estado para este widget.
}

// Estado de la pantalla que gestiona la lógica y el estado de las rutas guardadas.
class _ListadoRutasScreenState extends State<ListadoRutasScreen> {
  List<dynamic>? rutasGuardadas; // Lista de rutas obtenidas desde la API.

  @override
  void initState() {
    super.initState();
    _fetchRutas(); // Llama a la función para obtener las rutas al inicializar el estado.
  }

  // Función para obtener las rutas desde la API.
  Future<void> _fetchRutas() async {
    await makeRequest(
      method: GET,
      url: ROUTES, // URL de la API para obtener rutas.
      onOk: (response) {
        setState(() {
          rutasGuardadas = jsonDecode(response.body); // Decodifica y guarda las rutas en el estado.
        });
      },
      onError: (response) {
        // Muestra un mensaje de error en caso de fallo de la solicitud.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar las rutas')),
        );
      },
      onDefault: (response) {
        // Muestra un mensaje para errores inesperados con el código de error.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: ${response.statusCode}')),
        );
      },
      onConnectionError: (errorMessage) {
        // Manejo de error de conexión.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      },
    );
  }

  // Función para eliminar una ruta a través de la API.
  Future<void> _deleteRuta(int id) async {
    await makeRequest(
      method: DELETE,
      url: ROUTE_DETAIL,
      urlVars: {'id' :id}, // URL de la API para eliminar una ruta específica.
      onOk: (response) {
        setState(() {
          rutasGuardadas!.removeWhere((ruta) => ruta['id'] == id); // Elimina la ruta localmente.
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruta eliminada con éxito')),
        );
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar la ruta')),
        );
      },
      onConnectionError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      },
    );
  }

  // Muestra un cuadro de diálogo de confirmación antes de eliminar una ruta.
  Future<void> _confirmDelete(BuildContext context, int id) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar esta ruta? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Cancela la acción.
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirma la acción de eliminación.
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      _deleteRuta(id); // Llama a la función para eliminar la ruta si se confirma.
    }
  }

  // Obtiene los puntos de la ruta desde el backend.
  Future<List<LatLng>> _fetchRoutePoints(int routeId) async {
    final List<LatLng> points = []; // Lista para almacenar los puntos

    await makeRequest(
      method: GET,
      url:  ROUTE_DETAIL,
      urlVars: {'id': routeId}, // Llama al backend con el ID de la ruta.
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

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;

    // Muestra el contenido dependiendo del estado de rutasGuardadas.
    if (rutasGuardadas == null) {
      // Pantalla de carga.
      bodyContent = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text(
              'Cargando rutas...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    } else if (rutasGuardadas!.isEmpty) {
      // Mensaje cuando no hay rutas.
      bodyContent = const Center(
        child: Text(
          "No hay rutas para mostrar",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else {
      // Lista de rutas cargadas.
      bodyContent = ListView.builder(
        itemCount: rutasGuardadas!.length,
        itemBuilder: (context, index) {
          final ruta = rutasGuardadas![index]; // Obtiene la ruta actual.

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
                  Text('Dificultad: ${ruta['dificultad']}'), // Muestra la dificultad de la ruta.
                ],
              ),
              leading: const Icon(Icons.map, color: Color(0xFF50C9B5)), // Icono de la ruta.
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red), // Icono para eliminar la ruta.
                onPressed: () {
                  _confirmDelete(context, ruta['id']); // Confirma eliminación de la ruta.
                },
              ),
              onTap: () async {
                // Navega a DetalleRutaScreen y actualiza las rutas tras regresar.
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleRutaScreen(ruta: ruta),
                  ),
                );

                if (result != null) {
                  _fetchRutas(); // Actualiza la lista de rutas si se regresó de la pantalla de detalles.
                }
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF50C9B5), // Color de fondo de la AppBar.
        title: Row(
          children: [
            logoWhite, // Logo de la aplicación.
            const SizedBox(width: 10),
            const Text('Listado de Rutas'), // Título de la pantalla.
          ],
        ),
      ),
      body: bodyContent, // Contenido del cuerpo.
    );
  }
}

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


  Future<void> updateRuta() async {
    // 1. Preparamos los datos actualizados en un mapa.
    final Map<String, dynamic> updatedData = {
      'nombre': _nombreController.text.trim(), // Obtiene el nombre de la ruta del controlador.
      'descripcion': _descripcionController.text.trim(), // Obtiene la descripción de la ruta del controlador.
    };

    // 2. Realizamos la solicitud PATCH al backend.
    await makeRequest(
      method: PATCH,
      url: ROUTE_DETAIL, // La URL del endpoint donde se actualiza la ruta.
      urlVars: {'id': widget.ruta['id']}, // El ID de la ruta que queremos actualizar.
      body: updatedData, // Pasa el mapa directamente en lugar de convertirlo a un JSON.
      onOk: (response) {
        // 3. Si la solicitud es exitosa, mostramos un mensaje de éxito.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruta actualizada exitosamente')),
        );
        setState(() {
          _isEditing = false; // Desactivamos el modo de edición.
        });
      },
      onError: (response) {
        // 4. Si hay un error, mostramos un mensaje de error.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la ruta')),
        );
      },
      onConnectionError: (errorMessage) {
        // 5. Si hay un error de conexión, mostramos un mensaje de error.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );
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
                if (_isEditing) {
                  // Si estamos en modo edición, llamamos a updateRuta para guardar los cambios.
                  updateRuta();
                } else {
                  // Si no estamos en modo edición, activamos el modo edición.
                  setState(() {
                    _isEditing = true;
                  });
                }
              },
              child: Text(
                _isEditing ? 'Guardar' : 'Editar', // Cambiamos el texto del botón según el estado.
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
