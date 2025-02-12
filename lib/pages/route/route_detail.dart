import 'dart:convert';

import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:itrek/helpers/config.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/map.dart';
import 'package:itrek/helpers/numbers.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String? errorMessage;
  double? _myRate;
  final TextEditingController _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.ruta['nombre']);
    _descripcionController = TextEditingController(text: widget.ruta['descripcion']);
    _mapController = MapController();
    _myRate = (widget.ruta['mi_puntaje'] as num?)?.toDouble();
    _fetchLocalUsername();
    _loadRoutePoints();
    _comments = List<Map<String, dynamic>>.from(widget.ruta['comentarios'] ?? []);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _searchController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final commentText = _commentController.text.trim();
    if (commentText.isEmpty) return;

    final username = await db.values.get(db.values.username);

    // Prepara el nuevo comentario
    final newComment = {
      'usuario': username,
      'contenido': commentText,
    };

    await makeRequest(
      method: POST,
      url: ROUTE_COMMENT,
      urlVars: {'id': widget.ruta['id']},
      body: {'comment': commentText},
      onOk: (response) {
        _commentController.clear();

        final data = jsonDecode(response.body);
        setState(() {
          widget.ruta['comentarios'] = data['comentarios'];
          _comments = List<Map<String, dynamic>>.from(widget.ruta['comentarios']);
          print('los comentarios $_comments');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comentario enviado exitosamente')),
        );
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al enviar el comentario')),
        );
      },
      onConnectionError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );
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
        widget.ruta['distancia_km'] = distanciaKm;
      }
    } else {
      // Cargar puntos desde un origen remoto
      points = await _fetchRoutePoints();
    }

    // Actualizar el estado con los puntos cargados
    setState(() {
      routePoints = points;
    });

    // Actualizar puntos clave (si corresponde)
    _updateInterestPoints();
  }

  Future<List<LatLng>> _fetchRoutePoints() async {
    final List<LatLng> points = [];
    print('la ruta ${widget.ruta.containsKey('puntos') ? '' : 'no '}tiene puntos, y todo esto ${widget.ruta}');
    if (!widget.ruta.containsKey('puntos') || !widget.ruta.containsKey('comentarios')) {
      await makeRequest(
        method: GET,
        url: ROUTE_DETAIL,
        urlVars: {'id': widget.ruta['id']},
        onOk: (response) async {
          final jsonResponse = jsonDecode(response.body);
          widget.ruta['puntos'] = jsonResponse['puntos'];
          widget.ruta['comentarios'] = jsonResponse['comentarios'];
          setState(() {
            _comments = List<Map<String, dynamic>>.from(widget.ruta['comentarios']);
          });
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
    }

    points.addAll(widget.ruta['puntos'].map<LatLng>((punto) => LatLng(punto['latitud'], punto['longitud'])));
    await db.routes.createBackendRoute(widget.ruta);
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

  Future<void> _enviarValoracion(double rating) async {
    if (rating <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se puede enviar una calificación de 0')),
      );
      return;
    }

    await makeRequest(
      method: POST,
      url: ROUTE_RATING,
      urlVars: {'id': widget.ruta['id']},
      body: {'puntaje': rating},
      onOk: (response) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        final nuevoPuntaje = (responseData['puntaje'] as num?)?.toDouble() ?? 0.0;
        final miPuntaje = (responseData['mi_puntaje'] as num?)?.toDouble() ?? 0.0;
        final mensaje = responseData['message'] as String? ?? '¡Gracias por tu valoración!';

        setState(() {
          widget.ruta['puntaje'] = nuevoPuntaje;
          widget.ruta['mi_puntaje'] = miPuntaje;
          _myRate = miPuntaje;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensaje)),
        );
      },
      onError: (response) {
        print('Error del backend: ${response.statusCode} - ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar valoración: ${response.body}')),
        );
      },
      onConnectionError: (errorMessage) {
        print('Error de conexión: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );
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
        SnackBar(content: Text('Error al cargar puntos clave: $e')),
      );
    }
  }

  Future<void> updateRuta() async {
    final Map<String, dynamic> updatedData = {
      'nombre': _nombreController.text.trim(),
      'descripcion': _descripcionController.text.trim(),
      'publica': widget.ruta['publica'],
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
        url: ROUTES,
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

  // Función para eliminar una ruta a través de la API.
  Future<void> _deleteRuta(int id) async {
    await makeRequest(
      method: DELETE,
      url: ROUTE_DETAIL,
      urlVars: {'id': id},
      onOk: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ruta eliminada con éxito')),
        );
        // Navegar de regreso a la pantalla anterior después de eliminar
        Navigator.of(context).pop(true);
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

  // Definir el método _confirmDelete
  void _confirmDelete(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: const Text('¿Estás seguro de que deseas eliminar esta ruta? Esta acción no se puede deshacer.'),
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
                _deleteRuta(id);
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
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
                          puntaje > 0.0 ? conDecimales.format(puntaje) : '---',
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
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
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
                        ],
                      ),
                      const SizedBox(height: 10),
                      Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                  Text('Distancia: ${formatDistancia(widget.ruta['distancia_km'])} km'),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        widget.ruta['publica'] ? Icons.public : Icons.public_off,
                                        color: colorScheme.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        widget.ruta['publica'] ? 'Pública' : 'Privada',
                                      ),
                                    ],
                                  ),
                                  if (_isEditing && esPropietario)
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
                              Row(
                                children: [
                                  Icon(Icons.person, color: colorScheme.primary),
                                  const SizedBox(width: 10),
                                  Text('Creador: ${widget.ruta['usuario']['username']}',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sección de calificación
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 20),
                                const Text(
                                  'Calificar esta ruta:',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 15),
                                RatingBar.builder(
                                  initialRating: _myRate ?? 0,
                                  minRating: 1,
                                  direction: Axis.horizontal,
                                  allowHalfRating: false,
                                  itemCount: 5,
                                  itemSize: 30.0,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  onRatingUpdate: (rating) {
                                    setState(() {
                                      _myRate = _myRate == rating ? null : rating;
                                    });
                                    if (_myRate != null) {
                                      _enviarValoracion(_myRate!);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Se canceló la calificación')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Línea divisoria
                      const Divider(thickness: 2),
                      // Sección de comentarios
                      const SizedBox(height: 20),
                      const Text(
                        'Comentarios:',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          labelText: 'Escribe un comentario',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: null,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _submitComment,
                        child: const Text('Enviar Comentario'),
                      ),
                      const SizedBox(height: 20),
                      _comments.isEmpty
                          ? const Text('No hay comentarios aún.')
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage('$BASE_URL/${comment['usuario']['imagen_perfil']}'),
                              radius: 20,
                              backgroundColor: Colors.grey.shade200,
                            ),
                            title: Row(
                              children: [
                                Text(
                                  comment['usuario']['username'],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  comment['usuario']['nombre_nivel'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(comment['descripcion']),
                          );
                        },
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
              if (esPropietario)
                CircleIconButton(
                  icon: _isEditing ? Icons.save : Icons.edit,
                  color: colorScheme.primary,
                  onPressed: _isEditing
                      ? updateRuta
                      : () => setState(() => _isEditing = true),
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
              // Agregar el botón de eliminar solo si es el propietario
              if (esPropietario)
                CircleIconButton(
                  icon: Icons.delete,
                  color: Colors.red.shade800,
                  onPressed: () => _confirmDelete(context, widget.ruta['id']),
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
