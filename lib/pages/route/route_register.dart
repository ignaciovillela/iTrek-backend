import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itrek/db.dart';
import 'package:itrek/map.dart';
import 'package:itrek/pages/route/route_register_form.dart';
import 'package:itrek/request.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
Future<Map<String, dynamic>> getPostRouteData(
    String routeId, int seconds, double distanceTraveled) async {
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

  await makeRequest(
    method: POST,
    url: ROUTES,
    body: rutaData,
    onOk: (response) {
      final responseData = jsonDecode(response.body);
      rutaId = responseData['id'];
    },
    onError: (response) {
      print('Error al crear la ruta: ${response.statusCode}');
    },
    onConnectionError: (errorMessage) {
      print('Error en la solicitud: $errorMessage');
    },
  );

  return rutaId;
}

// Función para actualizar la ruta con datos adicionales usando PATCH
Future<void> _updateRuta(int id, String nombre, String descripcion,
    String dificultad, double distanciaKm, int tiempoEstimadoMinutos) async {
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
  bool centerMap = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  MapController mapController = MapController();

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
      centerMap = false;
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
          // Actualizar la notificación si está activa
          if (notiActiva) {
            _actualizarNotificacion();
          }
        });
      }
    });

    // Iniciar notificación
    _mostrarNotificacion();

    _iniciarSeguimientoUbicacion();
  }

  void _iniciarSeguimientoUbicacion() async {
    _routeId = await db.routes.createLocalRoute({
      'nombre': '',
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
    _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(distanceFilter: 10))
        .listen((Position position) {
      LatLng nuevaPosicion = LatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _currentPosition = nuevaPosicion;
          _currentPositionMarker = buildLocationMarker(_currentPosition!);
        });
      }

      if (centerMap) {
        mapController.move(nuevaPosicion, 18.0);
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
    final routeData = await getPostRouteData(_routeId!, _seconds, _distanceTraveled);
    int? rutaId = await postRuta(routeData);
    if (rutaId != null) {
      db.routes.deleteRoute(_routeId!);
      _borrarRegistro();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RutaFormPage(
            rutaId: rutaId,
            distanceTraveled: _distanceTraveled,
            secondsElapsed: _seconds,
            onSave: (rutaData) {
              _updateRuta(
                rutaId,
                rutaData['nombre'],
                rutaData['descripcion'],
                rutaData['dificultad'],
                _distanceTraveled ~/ 100 / 10,
                _seconds ~/ 60,
              );
              Navigator.of(context).pop();
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else {
      print('Error al enviar la ruta al backend');
    }
  }

  Future<void> _mostrarModalAgregarPuntoInteres() async {
    final TextEditingController descripcionController = TextEditingController();
    Uint8List? imagen;

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descripcionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? imageFile = await picker.pickImage(source: ImageSource.camera);
                  if (imageFile != null) {
                    imagen = await imageFile.readAsBytes();
                    imagen = Uint8List.fromList(imagen!.toList());
                  }
                },
                child: const Text('Seleccionar Imagen (Opcional)'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final data = {
                    'interes_descripcion': descripcionController.text,
                    'interes_imagen':
                    imagen != null ? base64Encode(imagen!) : null,
                  };
                  db.routes.updatePunto(_lastPointId!, data);
                  Navigator.pop(context);
                },
                child: const Text('Guardar Punto de Interés'),
              ),
            ],
          ),
        );
      },
    );
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
            const SnackBar(
              content: Text(
                  'Recuerda activar las notificaciones en tu dispositivo para ver el avance de tu ruta'),
            ),
          );
        }
      });
      _mostrarMensajeNotificacionDenegada = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio de Ruta'),
        backgroundColor: Colors.green.shade700,
      ),
      body: _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          buildMap(
            mapController: mapController,
            initialPosition: _currentPosition,
            routePolylines: [_previousRoutePolyline, _routePolyline],
            onPositionChanged: _handleMapMovement,
            markers: [
              ..._markers,
              if (_currentPositionMarker != null)
                _currentPositionMarker!,
              ..._interestPoints,
            ],
          ),
          Positioned(
            bottom: 105,
            right: 10,
            child: FloatingActionButton(
              onPressed: () {
                centerMap = true;
                if (_currentPosition != null) {
                  mapController.move(_currentPosition!, 18.0);
                }
              },
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              children: [
                Text(
                  'Tiempo: ${_formatTime(_seconds)}',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  'Distancia: ${_formatDistance(_distanceTraveled)}',
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Positioned(
            left: 20,
            right: 60,
            bottom: 90,
            child: ElevatedButton(
              onPressed: () async {
                _mostrarModalAgregarPuntoInteres();
              },
              child: const Text('Agregar Punto de Interés'),
            ),
          ),
          Positioned(
            left: 20,
            right: 60,
            bottom: 30,
            child: ElevatedButton(
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
              child: Text(_isRecording ? 'Finalizar Ruta' : 'Iniciar Registro'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(2)} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
  }
}
