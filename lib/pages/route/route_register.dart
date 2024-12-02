import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/map.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/route/route_list.dart';
import 'package:itrek/pages/route/route_register_form.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';

/// Solicitar permisos de ubicación en primer plano y, si es necesario, en segundo plano
Future<void> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.deniedForever) {
    throw 'Los permisos de ubicación están denegados permanentemente.';
  }

  if (permission == LocationPermission.whileInUse) {
    permission = await Geolocator.requestPermission();
    if (permission != LocationPermission.always) {
      throw 'Se necesita permiso de ubicación en segundo plano.';
    }
  }

  if (permission != LocationPermission.always) {
    throw 'Se necesitan permisos de ubicación para continuar.';
  }
}

/// Solicitar permiso de notificaciones
Future<void> requestNotificationPermission() async {
  var status = await Permission.notification.status;

  if (status.isDenied || status.isPermanentlyDenied) {
    status = await Permission.notification.request();
    if (status.isDenied || status.isPermanentlyDenied) {
      throw 'notificaciones_denegadas';
    }
  }
}


// Función para convertir una lista de coordenadas LatLng a un formato JSON
Future<Map<String, dynamic>> getPostRouteData(String routeId, int seconds, double distanceTraveled) async {
  final routeData = await db.routes.getRouteById(routeId);
  final pointsData = await db.routes.getPuntosByRutaId(routeId);

  return {
    'nombre': routeData?['nombre'],
    'descripcion': routeData?['descripcion'],
    'dificultad': routeData?['dificultad'],
    'distancia_km': distanceTraveled / 1000,
    'tiempo_estimado_minutos': seconds ~/ 60,
    'puntos': getPointsData(pointsData),
  };
}

List<Map<String, dynamic>> getPointsData(List<Map<String, dynamic>> points) {
  return List<Map<String, dynamic>>.generate(points.length, (index) {
    final point = points[index];
    return {
      'latitud': point['latitud'],
      'longitud': point['longitud'],
      'orden': point['orden'],
      'interes': {
        if (point['interes_descripcion'] != null) 'descripcion': point['interes_descripcion'],
        if (point['interes_imagen'] != null) 'imagen': point['interes_imagen'],
      },
      'interes_descripcion': point['interes_descripcion'],
      'interes_imagen': point['interes_imagen'],
    };
  });
}

// Función para enviar una ruta al backend mediante una solicitud HTTP POST
Future<int?> postRuta(Map<String, dynamic> rutaData) async {
  int? rutaId;
  print('rutaData: $rutaData');
  await makeRequest(
    method: POST,
    url: ROUTES,
    body: rutaData,
    onOk: (response) {
      final responseData = jsonDecode(response.body);
      print('responseData: $responseData');
      rutaId = responseData['id'];
    },
    onError: (response) {
      print('Error al crear la ruta: ${response.statusCode}');
      print('Mensaje de error: ${response.body}');
    },
    onConnectionError: (errorMessage) {
      print('Error en la solicitud: $errorMessage');
    },
  );

  return rutaId;
}

// Función para actualizar la ruta con datos adicionales usando PATCH
Future<void> _updateRuta(int id, String nombre, String descripcion, String dificultad, double distanciaKm, int tiempoEstimadoMinutos, bool publica) async {
  await makeRequest(
    method: PATCH,
    url: ROUTE_DETAIL,
    urlVars: {'id': id},
    body: {
      'nombre': nombre,
      'descripcion': descripcion,
      'dificultad': dificultad,
      'distancia_km': distanciaKm,
      'tiempo_estimado_minutos': tiempoEstimadoMinutos,
      'publica': publica,
    },
    onOk: (response) {
      print('Ruta actualizada con éxito');
    },
    onError: (response) {
      print('Error al actualizar la ruta: ${response.statusCode}');
    },
    onConnectionError: (errorMessage) {
      print('Error de conexión al actualizar la ruta: $errorMessage');
    },
  );
}

// Página principal del mapa donde se graba la ruta usando flutter_map
class RegistrarRuta extends StatefulWidget {
  final String? initialRouteId;
  const RegistrarRuta({super.key, this.initialRouteId});

  @override
  RegistrarRutaState createState() => RegistrarRutaState();
}

class RegistrarRutaState extends State<RegistrarRuta> {
  Marker? _currentPositionMarker;
  String? _routeId;
  int? _lastPointId;
  final List<Marker> _markers = [];
  final List<LatLng> _routeCoords = [];
  Polyline _previousRoutePolyline = Polyline(
    points: [],
    strokeWidth: 5,
    color: Colors.blue,
  );
  Polyline _routePolyline = Polyline(
    points: [],
    strokeWidth: 5,
    color: Colors.blue,
  );
  final List<Marker> _interestPoints = [];
  bool _isRecording = false;
  Timer? _timer;
  int _seconds = 0;
  double _distanceTraveled = 0.0;
  LatLng? _currentPosition;
  bool centerMap = true;
  StreamSubscription<Position>? _positionStreamSubscription;
  MapController mapController = MapController();
  bool _mapReady = false;

  // Variable para el plugin de notificaciones renombrada a notification
  FlutterLocalNotificationsPlugin notification = FlutterLocalNotificationsPlugin();

  // Variables para controlar el estado de la notificación
  int notiId = 0;
  bool notiActiva = false;

  // Variable para controlar si se debe mostrar el mensaje de notificación denegada
  bool _mostrarMensajeNotificacionDenegada = false;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePermissionsAndLocation();
    });
    _iniciarSeguimientoUbicacionSinRegistro();

    if (widget.initialRouteId != null) {
      db.routes.getPuntosByRutaId(widget.initialRouteId!).then((pointsData) {
        final List<LatLng> routeCoords = pointsData.map((point) {
          final position = LatLng(point['latitud'], point['longitud']);
          if (point['interes_descripcion'] != null || point['interes_imagen'] != null) {
            _interestPoints.add(buildInterestMarker(
              position: position,
              text: point['interes_descripcion'],
              base64Image: point['interes_imagen'],
              context: context,
            ));
          }
          return position;
        }).toList();
        _previousRoutePolyline = buildPreviousPloyline(routeCoords);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializePermissionsAndLocation() async {
    try {
      await requestLocationPermission();
    } catch (e) {
      // Manejar errores de permiso de ubicación
      print(e);
      return;
    }

    try {
      await requestNotificationPermission();
    } catch (e) {
      if (e == 'notificaciones_denegadas') {
        setState(() {
          _mostrarMensajeNotificacionDenegada = true;
        });
      }
    }

    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(),
    );
    if (mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _currentPositionMarker = buildLocationMarker(_currentPosition!);
      });
    }
  }

  /// Función que maneja el evento de movimiento del mapa
  void _handleMapMovement(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      setState(() {
        centerMap = false;
      });
    }
  }

  void _iniciarRegistro() {
    setState(() {
      _isRecording = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
          if (notiActiva) {
            _actualizarNotificacion();
          }
        });
      }
    });
    _mostrarNotificacion();

    _iniciarSeguimientoUbicacion();
  }

  void _iniciarSeguimientoUbicacion() async {
    _routeId = await db.routes.createLocalRoute({
      'nombre': 'Ruta local',
      'descripcion': '',
      'dificultad': '',
      'creado_en': '',
      'distancia_km': 0,
      'tiempo_estimado_minutos': 0,
      'usuario_username': '',
      'usuario_email': '',
      'usuario_first_name': '',
      'usuario_last_name': '',
      'usuario_biografia': '',
      'usuario_imagen_perfil': '',
      'publica': 0,
    });

    if (_routeId == null) {
      print('No se pudo crear la ruta en la base de datos');
      setState(() {
        _isRecording = false;
      });
      _borrarRegistro();
      return;
    }

    _actualizarPosicion(
        _currentPosition!.latitude, _currentPosition!.longitude);

    _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(distanceFilter: 10))
        .listen((Position position) {
      _actualizarPosicion(position.latitude, position.longitude);
    });
  }

  // Función para seguir la ubicación sin grabar la ruta
  void _iniciarSeguimientoUbicacionSinRegistro() {
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(distanceFilter: 10),
    ).listen((Position position) {
      LatLng nuevaPosicion = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = nuevaPosicion;
          _currentPositionMarker = buildLocationMarker(_currentPosition!);
        });

        // Mueve el mapa solo si está listo
        if (_mapReady && centerMap) {
          mapController.move(nuevaPosicion, 18.0);
        }
      }
    });
  }

  void _actualizarPosicion(double latitude, double longitude) async {
    if (_isRecording) {
      _lastPointId = await db.routes.createPunto(_routeId!, {
        'latitud': latitude,
        'longitud': longitude,
        'orden': _routeCoords.length + 1, // Ajustar el orden
      });
      LatLng nuevaPosicion = LatLng(latitude, longitude);
      if (_routeCoords.isNotEmpty) {
        _distanceTraveled +=
            Distance().as(LengthUnit.Meter, _routeCoords.last, nuevaPosicion);
      }
      _routeCoords.add(nuevaPosicion);

      if (mounted) {
        setState(() {
          _currentPosition = nuevaPosicion;
          _routePolyline = Polyline(
            points: _routeCoords,
            strokeWidth: 5,
            color: Colors.blue,
          );
          _currentPositionMarker = buildLocationMarker(_currentPosition!);
        });
      }

      if (centerMap) {
        mapController.move(nuevaPosicion, 18.0);
      }
    }
  }

  void _borrarRegistro() async {
    _routeId = null;
    _routeCoords.clear();
    _distanceTraveled = 0.0;
    _seconds = 0;

    _timer?.cancel();
    _positionStreamSubscription?.cancel();

    // Cancelar notificación si está activa
    if (notiActiva) {
      _cancelarNotificacion();
    }

    if (mounted) {
      setState(() {
        _isRecording = false;
      });
    }
  }

  void _finalizarRegistro() async {
    print('Tiempo en segundos: $_seconds');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      final routeData = await getPostRouteData(_routeId!, _seconds, _distanceTraveled);
      int? rutaId = await postRuta(routeData);
      if (rutaId != null) {
        // Cerrar el diálogo de carga antes de navegar al formulario
        if (mounted) Navigator.pop(context);
        await _mostrarFormularioRuta(rutaId);
      } else {
        if (mounted) Navigator.pop(context);
        print('Error al enviar la ruta al servidor');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      print('Error durante la finalización de la ruta: $e');
    }
  }


  Future<void> _mostrarFormularioRuta(int rutaId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RutaFormPage(
          rutaId: rutaId,
          distanceTraveled: _distanceTraveled,
          secondsElapsed: _seconds,
          onSave: (rutaData) async {
            await _updateRuta(
              rutaId,
              rutaData['nombre'],
              rutaData['descripcion'],
              rutaData['dificultad'],
              _distanceTraveled / 1000,
              _seconds ~/ 60,
              rutaData['publica'],
            );
            _borrarRegistro();
            Navigator.of(context).pop();

            if (mounted) {
              Navigator.of(context).pop(); // Cierra el formulario
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) =>  ListadoRutasScreen()
                ),
              );
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  Future<void> _mostrarModalAgregarPuntoInteres() async {
    final TextEditingController descripcionController = TextEditingController();
    Uint8List? imagen;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                'Agregar Punto Clave',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Descripción:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Ingrese una descripción',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (imagen != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              imagen!,
                              height: 300,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: CircleIconButton(
                              icon: Icons.delete,
                              size: 40,
                              iconSize: 20,
                              color: Colors.white,
                              iconColor: Colors.red,
                              onPressed: () {
                                setModalState(() {
                                  imagen = null;
                                });
                              },
                              opacity: 0.7,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Text(
                      'Agregar Imagen:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: imagen != null ? Colors.grey : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: imagen != null
                              ? null
                              : () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? imageFile = await picker.pickImage(source: ImageSource.camera);

                            if (imageFile != null) {
                              Uint8List originalImageBytes = await imageFile.readAsBytes();
                              Uint8List resizedImageBytes = await _resizeImage(originalImageBytes, 800, 800);
                              setModalState(() {
                                imagen = resizedImageBytes;
                              });
                            }
                          },
                          icon: Icon(Icons.camera_alt),
                          label: Text('Cámara'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: imagen != null
                              ? null
                              : () async {
                            final ImagePicker picker = ImagePicker();
                            final XFile? imageFile = await picker.pickImage(source: ImageSource.gallery);

                            if (imageFile != null) {
                              Uint8List originalImageBytes = await imageFile.readAsBytes();
                              Uint8List resizedImageBytes = await _resizeImage(originalImageBytes, 800, 800);
                              setModalState(() {
                                imagen = resizedImageBytes;
                              });
                            }
                          },
                          icon: Icon(Icons.photo_library),
                          label: Text('Galería'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (descripcionController.text.trim().isEmpty && imagen == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Debe ingresar una descripción o seleccionar una imagen')),
                      );
                      return;
                    }
                    final data = {
                      'interes_descripcion': descripcionController.text.trim().isNotEmpty ? descripcionController.text.trim() : null,
                      'interes_imagen': imagen != null ? base64Encode(imagen!) : null,
                    };
                    db.routes.updatePunto(_lastPointId!, data);
                    Navigator.of(context).pop();
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Función para redimensionar la imagen
  Future<Uint8List> _resizeImage(Uint8List originalImage, int targetWidth, int targetHeight) async {
    // Decodificar la imagen a un formato que podamos manipular
    img.Image? decodedImage = img.decodeImage(originalImage);
    if (decodedImage == null) return originalImage;

    // Redimensionar la imagen
    img.Image resizedImage = img.copyResize(
      decodedImage,
      width: targetWidth,
      height: targetHeight,
    );

    // Convertir la imagen redimensionada a Uint8List para guardarla
    return Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));
  }

  // Métodos para notificaciones
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('notification_icon');

    const InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);

    await notification.initialize(initializationSettings);
  }

  Future<void> _mostrarNotificacion() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'itrek_channel', // id
      'iTrek', // title
      channelDescription: 'Notificación persistente para iTrek',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Hacer la notificación persistente
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await notification.show(
      notiId,
      'Grabando ruta',
      'Tiempo: ${_formatTime(_seconds)} - Distancia: ${_formatDistance(_distanceTraveled)}',
      platformChannelSpecifics,
    );

    notiActiva = true;
  }

  Future<void> _actualizarNotificacion() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'itrek_channel', // id
      'iTrek', // title
      channelDescription: 'Notificación persistente para iTrek',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true, // Hacer la notificación persistente
    );
    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await notification.show(
      notiId,
      'Grabando ruta',
      'Tiempo: ${_formatTime(_seconds)} - Distancia: ${_formatDistance(_distanceTraveled)}',
      platformChannelSpecifics,
    );
  }

  Future<void> _cancelarNotificacion() async {
    await notification.cancel(notiId);
    notiActiva = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_mostrarMensajeNotificacionDenegada) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Recuerda activar las notificaciones para ver el avance de tu ruta',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.orangeAccent.shade700,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
      _mostrarMensajeNotificacionDenegada = false;
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(title: 'Registrar Ruta'),
      body: _currentPosition == null
          ? const Center(
        child: CircularProgressIndicator(color: Colors.green),
      )
          : Stack(
        children: [
          // Mapa
          buildMap(
            mapController: mapController,
            initialPosition: _currentPosition,
            routePolylines: [_previousRoutePolyline, _routePolyline],
            onPositionChanged: _handleMapMovement,
            onMapReady: () {
              setState(() {
                _mapReady = true;
              });
            },
            markers: [
              ..._markers,
              if (_currentPositionMarker != null) _currentPositionMarker!,
              ..._interestPoints,
            ],
          ),

          // Indicadores de tiempo y distancia en la parte superior
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tiempo: ${_formatTime(_seconds)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Distancia: ${_formatDistance(_distanceTraveled)}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botones alineados en la parte inferior
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Botón para iniciar/finalizar grabación (alineado a la izquierda)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    _isRecording ? Colors.red.shade600 : Colors.green.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                  icon: Icon(
                    _isRecording ? Icons.stop : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    if (!_isRecording) {
                      final routes = await db.routes.getAllRoutes();
                      for (var route in routes) {
                        db.routes.deleteRoute(route['id']);
                      }
                      _iniciarRegistro();
                    } else {
                      _finalizarRegistro();
                    }
                  },
                  label: Text(
                    _isRecording ? 'Finalizar' : 'Iniciar',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),

                // Botones de íconos alineados a la derecha con fondo gris transparente
                Row(
                  children: [
                    // Botón para agregar punto clave (solo visible al grabar)
                    if (_isRecording)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add_location_alt,
                            color: Colors.blue,
                            size: 28,
                          ),
                          onPressed: _mostrarModalAgregarPuntoInteres,
                          tooltip: 'Agregar Punto Clave',
                        ),
                      ),

                    const SizedBox(width: 10),

                    // Botón para enfocar la posición actual (siempre visible)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.my_location,
                          color: centerMap ? Colors.green.shade600: Colors.grey.shade400,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            centerMap = true;
                          });
                          if (_currentPosition != null) {
                            mapController.move(_currentPosition!, 18.0);
                          }
                        },
                        tooltip: 'Enfocar',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      // Menos de 1 minuto: Mostrar solo segundos
      return '${seconds}s';
    } else if (seconds < 3600) {
      // Menos de 1 hora: Mostrar minutos y segundos
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      // Más de 1 hora: Mostrar horas, minutos y segundos
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      int remainingSeconds = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatDistance(double distanceInMeters) {
    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
  }
}
