import 'dart:convert'; // Importa la biblioteca para trabajar con JSON.

import 'package:flutter/material.dart'; // Importa el paquete de Flutter para crear interfaces de usuario.
import 'package:itrek/helpers/request.dart'; // Importa funciones para realizar solicitudes HTTP.
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/route/route_detail.dart';
import 'package:latlong2/latlong.dart'; // Importa el paquete para trabajar con coordenadas geográficas.
import 'package:itrek/helpers/db.dart'; // Importa RoutesHelper para gestionar la base de datos.

// Pantalla principal que muestra el listado de rutas guardadas.
class ListadoRutasScreen extends StatefulWidget {
  const ListadoRutasScreen({super.key}); // Constructor del widget.

  @override
  _ListadoRutasScreenState createState() => _ListadoRutasScreenState(); // Crea el estado para este widget.
}

// Estado de la pantalla que gestiona la lógica y el estado de las rutas guardadas.
class _ListadoRutasScreenState extends State<ListadoRutasScreen> {
  List<dynamic>? rutasGuardadas; // Lista de rutas obtenidas desde la API.
  List<dynamic>? rutasFiltradas; // Lista de rutas después de aplicar el filtro.
  List<dynamic>? rutasLocales; // Lista de rutas locales obtenidas de SQLite.
  bool mostrarRutasLocales = true; // Indica si se deben mostrar solo rutas locales.


  @override
  void initState() {
    super.initState();
    _fetchRutas(); // Llama a la función para obtener las rutas al inicializar el estado.
  }

  // Función para obtener las rutas desde la API.
  Future<void> _fetchRutas() async {
    // Cargar rutas locales desde la base de datos.
    final routesHelper = RoutesHelper.instance;
    rutasLocales = await routesHelper.getLocalRoutes();

    // Cargar rutas desde la API.
    await makeRequest(
      method: GET,
      url: ROUTES, // URL de la API para obtener rutas.
      onOk: (response) {
        setState(() {
          rutasGuardadas = jsonDecode(response.body); // Decodifica y guarda las rutas en el estado.
          _aplicarFiltro(); // Aplica el filtro inicial.
        });
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cargar las rutas')),
        );
      },
      onDefault: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inesperado: ${response.statusCode}')),
        );
      },
      onConnectionError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      },
    );
  }

  // Función para aplicar el filtro de rutas.
  void _aplicarFiltro() {
    if (mostrarRutasLocales) {
      // Mostrar solo las rutas locales almacenadas en el dispositivo.
      rutasFiltradas = rutasLocales;
    } else {
      // Muestra todas las rutas (locales y del backend).
      rutasFiltradas = [
        ...?rutasGuardadas, // Incluye rutas del backend.
        ...?rutasLocales // Incluye rutas locales.
      ];
    }
    setState(() {});
  }


  // Widget para mostrar los botones de filtro.
  Widget _buildFiltros() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () {
            setState(() {
              mostrarRutasLocales = false; // Mostrar todas las rutas.
              _aplicarFiltro();
            });
          },
          child: Text(
            'Todas',
            style: TextStyle(
              color: !mostrarRutasLocales ? Colors.blue : Colors.black,
              fontWeight: !mostrarRutasLocales ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              mostrarRutasLocales = true; // Mostrar solo rutas locales.
              _aplicarFiltro();
            });
          },
          child: Text(
            'Locales',
            style: TextStyle(
              color: mostrarRutasLocales ? Colors.blue : Colors.black,
              fontWeight: mostrarRutasLocales ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // Función para eliminar una ruta a través de la API.
  Future<void> _deleteRuta(int id) async {
    await makeRequest(
      method: DELETE,
      url: ROUTE_DETAIL,
      urlVars: {'id': id}, // URL de la API para eliminar una ruta específica.
      onOk: (response) {
        setState(() {
          rutasGuardadas!.removeWhere((ruta) => ruta['id'] == id); // Elimina la ruta localmente.
          _aplicarFiltro(); // Aplica el filtro después de eliminar.
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
      url: ROUTE_DETAIL,
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

    if (rutasFiltradas == null) {
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
    } else if (rutasFiltradas!.isEmpty) {
      bodyContent = const Center(
        child: Text(
          "No hay rutas para mostrar",
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else {
      bodyContent = ListView.builder(
        itemCount: rutasFiltradas!.length,
        itemBuilder: (context, index) {
          final ruta = rutasFiltradas![index]; // Obtiene la ruta actual.
          final esLocal = ruta.containsKey('local') && ruta['local'] == 1;  // Verifica si la ruta es local
          final cardColor = esLocal ? Colors.green.shade50 : null; // Define el color del Card basado en el estado // Define el color basado en el estado

          return Card(
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
            color: cardColor,
            child: ListTile(
              title: Text(
                ruta['nombre'],
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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
              trailing: CircleIconButton(
                icon: Icons.delete,
                color: Colors.red.shade100,
                iconColor: Colors.red.shade800,
                onPressed: () {
                  _confirmDelete(context, ruta['id']);
                },
                size: 40,
                iconSize: 20,
                opacity: 0.8,
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetalleRutaScreen(ruta: ruta),
                  ),
                );
                _fetchRutas();
              },
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Listado de Rutas'),
      body: Column(
        children: [
          _buildFiltros(),
          Expanded(child: bodyContent),
        ],
      ),
    );
  }
}
