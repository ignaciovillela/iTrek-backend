import 'dart:convert'; // Importa la biblioteca para trabajar con JSON.

import 'package:flutter/material.dart'; // Importa el paquete de Flutter para crear interfaces de usuario.
import 'package:itrek/img.dart'; // Importa recursos de imagen.
import 'package:itrek/pages/route/route_detail.dart';
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

                if (result == true) {
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
