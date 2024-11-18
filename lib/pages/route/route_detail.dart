import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:itrek/db.dart';
import 'package:itrek/img.dart';
import 'package:itrek/map.dart';
import 'package:itrek/pages/route/route_register.dart';
import 'package:itrek/request.dart';
import 'package:latlong2/latlong.dart';

class DetalleRutaScreen extends StatefulWidget {
  final Map<String, dynamic> ruta;

  const DetalleRutaScreen({super.key, required this.ruta});

  @override
  _DetalleRutaScreenState createState() => _DetalleRutaScreenState();
}

class _DetalleRutaScreenState extends State<DetalleRutaScreen> {
  bool _isEditing = false;
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  String? localUsername;
  bool esPropietario = false;
  List<dynamic>? usuariosFiltrados;
  TextEditingController _searchController = TextEditingController();
  String? errorMessage;
  late MapController _mapController;
  List<LatLng> routePoints = [];
  final List<Marker> _interestPoints = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.ruta['nombre']);
    _descripcionController = TextEditingController(text: widget.ruta['descripcion']);
    _mapController = MapController();
    _fetchLocalUsername();
    _loadRoutePoints();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocalUsername() async {
    final username = await db.values.get(db.values.username);
    setState(() {
      localUsername = username;
      esPropietario = localUsername == widget.ruta['usuario']['username'];
    });
  }

  Future<void> updateRuta() async {
    final Map<String, dynamic> updatedData = {
      'nombre': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
    };

    await makeRequest(
      method: PATCH,
      url: ROUTE_DETAIL,
      urlVars: {'id': widget.ruta['id']},
      body: updatedData,
      onOk: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruta actualizada exitosamente')),
        );
        setState(() {
          _isEditing = false;
        });
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al actualizar la ruta')),
        );
      },
      onConnectionError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );
  }

  Future<void> _updateInterestPoints() async {
    // Limpiar la lista actual de puntos de interés antes de agregar nuevos
    _interestPoints.clear();

    // Obtener los puntos desde la base de datos local
    final pointsData = await db.routes.getPuntosByRutaId(widget.ruta['id'].toString());

    setState(() {
      for (var point in pointsData) {
        final position = LatLng(point['latitud'], point['longitud']);

        // Verificar si hay una descripción o una imagen para el punto de interés
        if (point['interes_descripcion'] != null || point['interes_imagen'] != null) {
          _interestPoints.add(buildInterestMarker(
            position: position,
            text: point['interes_descripcion'],
            base64Image: point['interes_imagen'],
            context: context,
          ));
        }
      }
    });
  }

  Future<void> _loadRoutePoints() async {
    if (widget.ruta['local'] == 1) {
      // Si la ruta es local, cargar los puntos de la base de datos local
      final pointsData = await db.routes.getPuntosByRutaId(widget.ruta['id'].toString());
      final List<LatLng> points = pointsData.map((point) => LatLng(point['latitud'], point['longitud'])).toList();

      setState(() {
        routePoints = points;
      });
      _updateInterestPoints(); // Actualiza los puntos de interés
    } else {
      // Si la ruta no es local, realizar la solicitud a la API
      final List<LatLng> points = await _fetchRoutePoints();
      setState(() {
        routePoints = points;
      });
      _updateInterestPoints(); // Actualiza los puntos de interés
    }
  }


  Future<List<LatLng>> _fetchRoutePoints() async {
    final List<LatLng> points = [];
    try {
      await makeRequest(
        method: GET,
        url: ROUTE_DETAIL,
        urlVars: {'id': widget.ruta['id']},
        onOk: (response) async {
          final jsonResponse = jsonDecode(response.body);
          points.addAll(
            jsonResponse['puntos'].map<LatLng>((punto) => LatLng(punto['latitud'], punto['longitud'])),
          );

          // Guarda la ruta en la base de datos local
          await db.routes.createBackendRoute(jsonResponse);

          // Cargar puntos de la base de datos local
          final pointsData = await db.routes.getPuntosByRutaId(widget.ruta['id'].toString());
          setState(() {
            _interestPoints.clear();
            pointsData.forEach((point) {
              final position = LatLng(point['latitud'], point['longitud']);
              if (point['interes_descripcion'] != null || point['interes_imagen'] != null) {
                _interestPoints.add(buildInterestMarker(
                  position: position,
                  text: point['interes_descripcion'],
                  base64Image: point['interes_imagen'],
                  context: context,
                ));
              }
            });
          });
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
    } catch (e) {
      print('Error al obtener los puntos de la ruta: $e');
    }
    return points;
  }

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
                            setModalState(() {});
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
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                if (errorMessage != null)
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
                          Navigator.pop(context);
                          _compartirRutaConUsuario(usuario['id']);
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
      urlVars: {'query': query},
      onOk: (response) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          usuariosFiltrados = data;
          errorMessage = null;
        });
      },
      onError: (response) {
        var errorData = jsonDecode(response.body);
        setState(() {
          errorMessage = errorData['error'];
          usuariosFiltrados = null;
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
  Future<void> guardarRutaEnBackend() async {
    // Obtener los datos de la ruta y los puntos desde la base de datos local
    final routeData = await db.routes.getRouteById(widget.ruta['id']);
    final pointsData = await db.routes.getPuntosByRutaId(widget.ruta['id'].toString());

    if (routeData != null) {
      final rutaData = {
        ...routeData,
        'puntos': pointsData,
      };

      // Enviar la ruta al backend
      makeRequest(
        method: POST,
        url: ROUTES,
        body: rutaData,
        onOk: (response) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ruta guardada en el backend exitosamente')),
          );
          setState(() {
            widget.ruta['local'] = 0; // Cambiar el estado de la ruta a no local
          });
        },
        onError: (response) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar la ruta en el backend')),
          );
        },
        onConnectionError: (errorMessage) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error de conexión: $errorMessage')),
          );
        },
      );
    }
  }

  Future<void> _compartirRutaConUsuario(int usuarioId) async {
    await makeRequest(
      method: POST,
      url: ROUTE_SHARE,
      urlVars: {'id': widget.ruta['id'], 'usuarioId': usuarioId},
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
            const Text("iTrek Detalles de Ruta"),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50), // Verde agradable para trekking
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80.0), // Deja espacio suficiente para los botones
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nombreController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de la Ruta',
                              labelStyle: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            enabled: _isEditing,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _descripcionController,
                            decoration: const InputDecoration(labelText: 'Descripción'),
                            style: const TextStyle(fontSize: 16),
                            enabled: _isEditing,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 10),
                          ListTile(
                            leading: const Icon(Icons.timeline, color: Color(0xFF4CAF50)),
                            title: Text('Dificultad: ${widget.ruta['dificultad']}'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.directions_walk, color: Color(0xFF4CAF50)),
                            title: Text('Distancia: ${widget.ruta['distancia_km']} km'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.timer, color: Color(0xFF4CAF50)),
                            title: Text('Tiempo estimado: ${widget.ruta['tiempo_estimado_minutos']} horas'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 4,
                    child: SizedBox(
                      height: 350,
                      child: routePoints.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : buildMap(
                        mapController: _mapController,
                        initialPosition: getCenterAndZoomForBounds(routePoints)['center'],
                        initialZoom: getCenterAndZoomForBounds(routePoints)['zoom'],
                        routePolylines: [buildPreviousPloyline(routePoints)],
                        markers: [
                          if (routePoints.isNotEmpty)
                            Marker(
                              point: routePoints.first,
                              width: 60,
                              height: 60,
                              child: Icon(Icons.location_on, color: Colors.green, size: 40),
                            ),
                          if (routePoints.isNotEmpty)
                            Marker(
                              point: routePoints.last,
                              width: 60,
                              height: 60,
                              child: Icon(Icons.flag, color: Colors.red, size: 40),
                            ),
                          ..._interestPoints,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(
                      _isEditing ? Icons.save : Icons.edit,
                      color: Colors.black,
                      size: 30,
                    ),
                    onPressed: _isEditing ? updateRuta : () => setState(() => _isEditing = true),
                    tooltip: _isEditing ? 'Guardar' : 'Editar',
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.directions_walk,
                      color: Colors.black,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RegistrarRuta(initialRouteId: widget.ruta['id'].toString()),
                        ),
                      );
                    },
                    tooltip: 'Recorrer Ruta',
                  ),
                  if (esPropietario)
                    IconButton(
                      icon: Icon(
                        Icons.share,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: _showUsuariosBottomSheet,
                      tooltip: 'Compartir Ruta',
                ),
              // Agrega este botón en el método build, debajo de los demás botones
              if (widget.ruta['local'] == 1)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: guardarRutaEnBackend,
                  child: const Text('Guardar en el Backend'),
                ),
            ],
          ),
        ),),
        ],
      ),
    );
  }
}
