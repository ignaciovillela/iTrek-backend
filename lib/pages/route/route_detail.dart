import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/map.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/text.dart';
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/route/route_register.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

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
    List<LatLng> points = [];
    double distanciaKm = 0.0;

    try {
      if (widget.ruta['local'] == 1) {
        // Obtener puntos de la ruta local
        final pointsData = await db.routes.getPuntosByRutaId(widget.ruta['id'].toString());
        if (pointsData.isNotEmpty) {
          points = pointsData.map((point) => LatLng(point['latitud'], point['longitud'])).toList();

          // Calcular la distancia total entre los puntos
          for (int i = 0; i < points.length - 1; i++) {
            distanciaKm += Distance().as(LengthUnit.Kilometer, points[i], points[i + 1]);
          }

          // Mostrar el tiempo desde la base de datos local
          final tiempoGrabadoMinutos = widget.ruta['tiempo_estimado_minutos'] ?? 0;

          // Actualizar la información en el widget
          widget.ruta['tiempo_estimado_minutos'] = tiempoGrabadoMinutos;
          widget.ruta['distancia_km'] = distanciaKm.toStringAsFixed(2);
        }
      } else {
        // Cargar puntos desde un origen remoto
        points = await _fetchRoutePoints();
      }
    } catch (error) {
      print('Error al cargar los puntos de la ruta: $error');
    }

    // Actualizar el estado con los puntos cargados
    setState(() {
      routePoints = points;
    });

    // Actualizar puntos de interés (si corresponde)
    _updateInterestPoints();
  }


  Future<List<LatLng>> _fetchRoutePoints() async {
    final List<LatLng> points = [];
    print('la ruta ${widget.ruta.containsKey('puntos') ? '' : 'no '}tiene puntos, y todo esto ${widget.ruta}');
    if (widget.ruta.containsKey('puntos')) {
      points.addAll(
          widget.ruta['puntos'].map<LatLng>((punto) => LatLng(punto['latitud'], punto['longitud']))
      );
      await db.routes.createBackendRoute(widget.ruta);
    } else {try {
      await makeRequest(
        method: GET,
        url: ROUTE_DETAIL,
        urlVars: {'id': widget.ruta['id']},
        onOk: (response) async {
          final jsonResponse = jsonDecode(response.body);
          points.addAll(
            jsonResponse['puntos'].map<LatLng>((punto) => LatLng(punto['latitud'], punto['longitud'])),
          );
          widget.ruta['tiempo_estimado_horas'] = jsonResponse['tiempo_estimado_horas'] ?? 0.0;
          widget.ruta['tiempo_estimado_minutos'] = (widget.ruta['tiempo_estimado_horas'] * 60).round();
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
    }
    return points;
  }
  String _formatHoras(dynamic tiempoEnMinutos) {
    if (tiempoEnMinutos == null) return '0 horas';

    final horas = tiempoEnMinutos ~/ 60;
    final minutos = tiempoEnMinutos % 60;

    String horasTexto = horas == 1 ? '1 hora' : '$horas horas';
    String minutosTexto = minutos == 1 ? '1 minuto' : '$minutos minutos';

    if (horas == 0) {
      return minutosTexto; // Solo minutos si no hay horas
    } else if (minutos == 0) {
      return horasTexto; // Solo horas si no hay minutos
    } else {
      return '$horasTexto y $minutosTexto'; // Horas y minutos
    }
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
      'publica': widget.ruta['publica'], // Incluye el atributo pública
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

  void _showUsuariosBottomSheet(routeId) {
    final String textToShare = shareRoute(routeId);

    // Llama al método para compartir
    Share.share(textToShare);
    return;
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

    final double puntaje = (widget.ruta['puntaje'] as num?)?.toDouble() ?? 0.0;
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
                // Colocar Estrellas en Mapa
                Stack(
                  children: [
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

                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              puntaje.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.star,
                              size: 20,
                              color: Colors.amber,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                          Text('Tiempo estimado: ${_formatHoras(widget.ruta['tiempo_estimado_minutos'])}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                widget.ruta['publica'] ? Icons.public : Icons.lock,
                                color: widget.ruta['publica'] ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.ruta['publica'] ? 'Pública' : 'Privada',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                          if (_isEditing) // Mostrar el interruptor solo en modo edición
                            Switch(
                              value: widget.ruta['publica'],
                              onChanged: (value) {
                                setState(() {
                                  widget.ruta['publica'] = value;
                                });
                              },
                            ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: colorScheme.primary),
                          const SizedBox(width: 10),
                          Text('Fecha de creación: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(widget.ruta['creado_en']))}',
                          ),
                        ],
                      ),
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
              CircleIconButton(
                icon: Icons.share,
                color: Colors.purple,
                onPressed: () => _showUsuariosBottomSheet(widget.ruta['id'].toString()),
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
