import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/map.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/route/route_register.dart';
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
  late MapController _mapController;
  List<LatLng> routePoints = [];
  final List<Marker> _interestPoints = [];
  String? localUsername;
  bool esPropietario = false;
  List<dynamic>? usuariosFiltrados;
  TextEditingController _searchController = TextEditingController();
  String? errorMessage;

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
      esPropietario = username == widget.ruta['usuario']['username'] || widget.ruta['local'] == 1;
    });
  }

  Future<void> _loadRoutePoints() async {
    late List<LatLng> points;
    if (widget.ruta['local'] == 1) {
      final pointsData = await db.routes.getPuntosByRutaId(widget.ruta['id'].toString());
      points = pointsData.map((point) => LatLng(point['latitud'], point['longitud'])).toList();
    } else {
      points = await _fetchRoutePoints();
    }
    setState(() {
      routePoints = points;
    });
    _updateInterestPoints();
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

          await db.routes.createBackendRoute(jsonResponse);
        },
        onError: (response) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar la ruta: ${response.body}')),
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

  Future<void> _updateInterestPoints() async {
    try {
      _interestPoints.clear();
      final pointsData = await db.routes.getPuntosByRutaId(widget.ruta['id'].toString());
      setState(() {
        for (var point in pointsData) {
          final position = LatLng(point['latitud'], point['longitud']);
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar puntos de interés: $e')),
      );
    }
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
    final routeId = widget.ruta['id'].toString();
    final routeData = await db.routes.getRouteById(routeId);
    final pointsData = await db.routes.getPuntosByRutaId(routeId);

    if (routeData != null) {
      final rutaData = {
        ...routeData,
        'puntos': pointsData,
      };

      // Enviar la ruta al backend
      makeRequest(
        method: POST,
        url: ROUTES, // Asegúrate de que esta URL esté correctamente configurada
        body: rutaData,
        onOk: (response) {
          db.routes.deleteRoute(routeId);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ruta guardada en el servidor exitosamente')),
          );
        },
        onError: (response) {
          print('Error al guardar la ruta: ${response.statusCode} - ${response.body}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al guardar la ruta en el servidor')),
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

  // Función para mostrar el modal
  void _mostrarGuardarRuta() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Guardar Ruta'),
          content: const Text('Esta es una ruta local. Se guardará en el servidor.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                guardarRutaEnBackend();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Evita que el footer se mueva con el teclado
      appBar: CustomAppBar(title: 'Detalle de Ruta'),
      body: Stack(
        children: [
          // Contenido principal con scroll
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Espacio para evitar solapamiento
            child: Column(
              children: [
                // Mapa
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.4,
                  child: routePoints.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : buildMap(
                    mapController: _mapController,
                    initialPosition: getCenterAndZoomForBounds(routePoints)['center'],
                    initialZoom: getCenterAndZoomForBounds(routePoints)['zoom'],
                    routePolylines: [buildPreviousPloyline(routePoints)],
                    markers: _interestPoints,
                  ),
                ),

                // Información de la ruta
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileTextField(
                        controller: _nombreController,
                        label: 'Nombre de la Ruta',
                        enabled: _isEditing,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 16),
                        enabled: _isEditing,
                        maxLines: null,
                        minLines: 3,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.timeline, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Text('Dificultad: ${widget.ruta['dificultad']}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.directions_walk, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Text('Distancia: ${widget.ruta['distancia_km']} km'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.timer, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Text('Tiempo estimado: ${widget.ruta['tiempo_estimado_minutos']} horas'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            widget.ruta['publica'] ? Icons.public : Icons.lock,
                            color: widget.ruta['publica'] ? Colors.green : Colors.red,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.ruta['publica'] == true ? 'Pública' : 'Privada',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Footer fijo con botones flotantes
          FixedFooter(
            children: [
              CircleIconButton(
                icon: _isEditing ? Icons.save : Icons.edit,
                color: _isEditing ? Colors.green : colorScheme.primary,
                onPressed: _isEditing ? updateRuta : () => setState(() => _isEditing = true),
              ),
              CircleIconButton(
                icon: Icons.directions_walk,
                color: Colors.blue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RegistrarRuta(initialRouteId: widget.ruta['id'].toString()),
                    ),
                  );
                },
              ),
              if (esPropietario)
                CircleIconButton(
                  icon: Icons.share,
                  color: Colors.purple,
                  onPressed: _showUsuariosBottomSheet,
                ),
              // Botón de guardar en el backend, se muestra si la ruta es local
              if (widget.ruta['local'] == 1)
                CircleIconButton(
                  icon: Icons.cloud_upload,
                  color: Colors.orange,
                  onPressed: _mostrarGuardarRuta,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
