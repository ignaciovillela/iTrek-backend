import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:itrek_maps/config.dart';

// Función para convertir una lista de coordenadas LatLng a un formato JSON
List<Map<String, dynamic>> convertirAFormato(List<LatLng> listaCoords) {
  return List<Map<String, dynamic>>.generate(listaCoords.length, (index) {
    return {
      "latitud": listaCoords[index].latitude,
      "longitud": listaCoords[index].longitude,
      "orden": index + 1,
    };
  });
}

// Función para enviar una ruta al backend mediante una solicitud HTTP POST
Future<int?> postRuta(Map<String, dynamic> rutaData) async {
  String url = '$BASE_URL/api/rutas/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json"
      },
      body: jsonEncode(rutaData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Ruta creada con éxito: ${response.body}');
      final responseData = jsonDecode(response.body);
      return responseData['id'];  // Suponemos que el backend devuelve un 'id'
    } else {
      print('Error al crear la ruta: ${response.statusCode}');
      print('Respuesta: ${response.body}');
    }
  } catch (e) {
    print('Error en la solicitud: $e');
  }
  return null;
}

// Función para actualizar la ruta con datos adicionales usando PATCH
Future<void> _updateRuta(int id, String nombre, String descripcion, String dificultad, double distanciaKm, double tiempoEstimadoHoras) async {
  // Crear el cuerpo de la solicitud
  final response = await http.patch(
    Uri.parse('$BASE_URL/api/rutas/$id/'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, dynamic>{
      'nombre': nombre, // Actualizamos el nombre
      'descripcion': descripcion, // Actualizamos la descripción
      'dificultad': dificultad, // Actualizamos la dificultad
      'distancia_km': distanciaKm, // Distancia en km
      'tiempo_estimado_horas': tiempoEstimadoHoras, // Tiempo estimado en horas
    }),
  );

  if (response.statusCode == 200) {
    print('Ruta actualizada con éxito');
  } else {
    print('Error al actualizar la ruta: ${response.statusCode}');
    print('Respuesta del servidor: ${response.body}');
  }
}

// Página principal del mapa de Google donde se graba la ruta
class GoogleMapsPage extends StatefulWidget {
  const GoogleMapsPage({Key? key}) : super(key: key);

  @override
  _GoogleMapsPageState createState() => _GoogleMapsPageState();
}

class _GoogleMapsPageState extends State<GoogleMapsPage> {
  final Map<String, Marker> _markers = {};
  GoogleMapController? _mapController;
  final List<LatLng> _routeCoords = [];
  Polyline _routePolyline = const Polyline(
    polylineId: PolylineId('route'),
    width: 5,
    color: Colors.blue,
  );
  bool _isRecording = false;
  Timer? _timer;
  Timer? _locationTimer;
  int _seconds = 0;
  double _distanceTraveled = 0.0;
  LatLng? _lastPosition;
  LatLng? _initialPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      _markers['currentPosition'] = Marker(
        markerId: const MarkerId('currentPosition'),
        position: _initialPosition!,
        infoWindow: const InfoWindow(
          title: 'Posición Actual',
          snippet: 'Ubicación obtenida del dispositivo',
        ),
      );
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition!, 18));
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    if (_initialPosition != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition!, 18));
    }
  }

  Future<void> _centrarEnPosicionActual() async {
    if (_lastPosition != null) {
      _moverCamara(_lastPosition!);
    }
  }

  void _moverCamara(LatLng nuevaPosicion) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(nuevaPosicion));
  }

  void _iniciarRegistro() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _seconds++;
          });
        }
      });

      _locationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
        _lastPosition ??= _initialPosition;

        Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
        final newPosition = LatLng(position.latitude, position.longitude);

        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        _distanceTraveled += distance;

        setState(() {
          _routeCoords.add(newPosition);
          _lastPosition = newPosition;

          _routePolyline = Polyline(
            polylineId: const PolylineId('route'),
            points: _routeCoords,
            width: 5,
            color: Colors.blue,
          );

          _markers['currentPosition'] = Marker(
            markerId: const MarkerId('currentPosition'),
            position: newPosition,
            infoWindow: InfoWindow(
              title: 'Distancia Recorrida',
              snippet: '${(_distanceTraveled / 1000).toStringAsFixed(2)} km',
            ),
          );
        });

        _moverCamara(newPosition);
      });
    } else {
      _timer?.cancel();
      _locationTimer?.cancel();
    }
  }

  void _finalizarRegistro() async {
    if (_isRecording) {
      _timer?.cancel();
      _locationTimer?.cancel();
      setState(() {
        _isRecording = false;
      });

      // Enviar puntos, tiempo y distancia al backend primero
      Map<String, dynamic> rutaData = {
        "puntos": convertirAFormato(_routeCoords),
        "tiempo_segundos": _seconds,
        "distancia_km": _distanceTraveled / 1000,
      };

      int? rutaId = await postRuta(rutaData);  // Guardar la ruta y obtener el ID

      if (rutaId != null) {
        _mostrarPantallaFormulario(rutaId);  // Mostrar el formulario para los detalles adicionales
      } else {
        print('Error al enviar la ruta inicial');
      }
    }
  }

  void _mostrarPantallaFormulario(int rutaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RutaFormPage(
          rutaId: rutaId,  // Pasamos el ID de la ruta creada
          distanceTraveled: _distanceTraveled,
          secondsElapsed: _seconds,
          onSave: (rutaData) {
            _updateRuta(
              rutaId,
              rutaData['nombre'],
              rutaData['descripcion'],
              rutaData['dificultad'],
              _distanceTraveled / 1000, // Pasamos la distancia en km
              _seconds / 3600, // Convertimos los segundos a horas
            );  // Enviar los datos adicionales al backend
            Navigator.of(context).pop();
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  void _mostrarConfirmacionFinalizar() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Finalizar Ruta'),
          content: const Text('¿Estás seguro de que deseas finalizar la ruta?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _finalizarRegistro();
                Navigator.of(context).pop();
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ruta'),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          _initialPosition == null
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition!,
              zoom: 18,
            ),
            markers: _markers.values.toSet(),
            polylines: {_routePolyline},
          ),
          Positioned(
            top: 20,
            left: 20,
            child: Column(
              children: [
                Text('Tiempo: ${_formatTime(_seconds)}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Text('Distancia: ${_formatDistance(_distanceTraveled)}',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              onPressed: _centrarEnPosicionActual,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _isRecording
                  ? _mostrarConfirmacionFinalizar
                  : _iniciarRegistro,
              child: Text(_isRecording ? 'Finalizar Ruta' : 'Iniciar Registro'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Página para agregar los detalles de la ruta después de finalizarla
class RutaFormPage extends StatefulWidget {
  final int rutaId;  // Recibir el ID de la ruta
  final double distanceTraveled;
  final int secondsElapsed;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const RutaFormPage({
    required this.rutaId,
    required this.distanceTraveled,
    required this.secondsElapsed,
    required this.onSave,
    required this.onCancel,
    Key? key,
  }) : super(key: key);

  @override
  _RutaFormPageState createState() => _RutaFormPageState();
}

class _RutaFormPageState extends State<RutaFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  String _descripcion = '';
  String _dificultad = 'facil';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Detalles de la Ruta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onSaved: (value) {
                  _nombre = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción'),
                onSaved: (value) {
                  _descripcion = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Dificultad'),
                value: _dificultad,
                items: const [
                  DropdownMenuItem(value: 'facil', child: Text('Fácil')),
                  DropdownMenuItem(value: 'moderada', child: Text('Moderado')),
                  DropdownMenuItem(value: 'dificil', child: Text('Difícil')),
                ],
                onChanged: (value) {
                  setState(() {
                    _dificultad = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        Map<String, dynamic> rutaData = {
                          "nombre": _nombre,
                          "descripcion": _descripcion,
                          "dificultad": _dificultad,
                        };

                        widget.onSave(rutaData);  // Enviar los datos al backend
                      }
                    },
                    child: const Text('Guardar Ruta'),
                  ),
                  ElevatedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancelar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
