import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// Función para convertir una lista de coordenadas LatLng a un formato JSON
List<Map<String, dynamic>> convertirAFormato(List<LatLng> listaCoords) {
  return List<Map<String, dynamic>>.generate(listaCoords.length, (index) {
    return {
      "latitud": listaCoords[index].latitude, // Latitud de la coordenada
      "longitud": listaCoords[index].longitude, // Longitud de la coordenada
      "orden": index + 1, // Orden en la lista (empezando desde 1)
    };
  });
}

// Función para enviar una ruta al backend mediante una solicitud HTTP POST
Future<void> postRuta(Map<String, dynamic> rutaData) async {
  const String url = 'http://10.20.4.151:8000/api/rutas/';
  try {
    final response = await http.post(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json"
      }, // Headers indicando que el contenido es JSON
      body: jsonEncode(rutaData), // Cuerpo de la solicitud en formato JSON
    );

    // Si la solicitud fue exitosa
    if (response.statusCode == 200 || response.statusCode == 201) {
      print(
          'Ruta creada con éxito: ${response.body}'); // Imprimir respuesta exitosa
    } else {
      print(
          'Error al crear la ruta: ${response.statusCode}'); // Imprimir código de error
      print(
          'Respuesta: ${response.body}'); // Imprimir la respuesta del servidor
    }
  } catch (e) {
    print(
        'Error en la solicitud: $e'); // Capturar e imprimir cualquier error en la solicitud
  }
}

// Página principal del mapa de Google donde se graba la ruta
class GoogleMapsPage extends StatefulWidget {
  const GoogleMapsPage({Key? key}) : super(key: key);

  @override
  _GoogleMapsPageState createState() => _GoogleMapsPageState();
}

class _GoogleMapsPageState extends State<GoogleMapsPage> {
  final Map<String, Marker> _markers = {}; // Mapa de marcadores
  GoogleMapController? _mapController; // Controlador del mapa
  final List<LatLng> _routeCoords = []; // Lista de coordenadas de la ruta
  Polyline _routePolyline = const Polyline(
    polylineId: PolylineId('route'), // ID de la línea polilínea
    width: 5, // Grosor de la línea
    color: Colors.blue, // Color de la línea
  );
  bool _isRecording = false; // Bandera para saber si se está grabando
  Timer? _timer; // Temporizador para el registro del tiempo
  Timer? _locationTimer; // Temporizador para simular movimiento
  int _seconds = 0; // Segundos transcurridos durante la grabación
  double _distanceTraveled = 0.0; // Distancia total recorrida
  LatLng? _lastPosition; // Última posición conocida
  LatLng? _initialPosition; // Posición inicial del dispositivo

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Obtener la ubicación actual al iniciar
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar temporizadores cuando el widget se destruye
    _locationTimer?.cancel();
    super.dispose();
  }

  // Función para obtener la ubicación actual del dispositivo
  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy:
          LocationAccuracy.high, // Usar alta precisión para obtener la posición
    );
    setState(() {
      _initialPosition = LatLng(position.latitude,
          position.longitude); // Establecer la ubicación inicial
      _markers['currentPosition'] = Marker(
        markerId: const MarkerId('currentPosition'), // ID del marcador
        position: _initialPosition!, // Posición del marcador
        infoWindow: const InfoWindow(
          title: 'Posición Actual',
          snippet: 'Ubicación obtenida del dispositivo',
        ),
      );
    });

    // Mover la cámara a la posición inicial
    _mapController
        ?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition!, 18));
  }

  // Función que se ejecuta cuando se crea el mapa de Google
  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    if (_initialPosition != null) {
      _mapController
          ?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition!, 18));
    }
  }

  // Centrar la cámara en la posición actual del dispositivo
  Future<void> _centrarEnPosicionActual() async {
    if (_lastPosition != null) {
      _moverCamara(_lastPosition!);
    }
  }

  // Mover la cámara a una nueva posición
  void _moverCamara(LatLng nuevaPosicion) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(nuevaPosicion));
  }

  // Iniciar el registro de la ruta
  void _iniciarRegistro() {
    setState(() {
      _isRecording = !_isRecording; // Alternar el estado de grabación
    });

    if (_isRecording) {
      // Temporizador para contar los segundos
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _seconds++; // Incrementar el contador de segundos
          });
        }
      });

      // Temporizador para simular el movimiento
      _locationTimer =
          Timer.periodic(const Duration(milliseconds: 1500), (timer) {
        if (_lastPosition == null) {
          _lastPosition = _initialPosition;
        }

        // Generar una nueva posición simulada
        LatLng newPosition = LatLng(
          _lastPosition!.latitude +
              0.0001, // Cambiar latitud para simular movimiento
          _lastPosition!.longitude +
              0.0001, // Cambiar longitud para simular movimiento
        );

        // Calcular la distancia entre la última posición y la nueva
        double distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          newPosition.latitude,
          newPosition.longitude,
        );
        _distanceTraveled += distance; // Acumular la distancia recorrida

        setState(() {
          _routeCoords.add(newPosition); // Agregar la nueva posición a la ruta
          _lastPosition = newPosition;

          // Actualizar la línea polilínea para mostrar la ruta
          _routePolyline = Polyline(
            polylineId: const PolylineId('route'),
            points: _routeCoords,
            width: 5,
            color: Colors.blue,
          );

          // Actualizar el marcador de posición actual
          _markers['currentPosition'] = Marker(
            markerId: const MarkerId('currentPosition'),
            position: newPosition,
            infoWindow: InfoWindow(
              title: 'Distancia Recorrida',
              snippet:
                  '${(_distanceTraveled / 1000).toStringAsFixed(2)} km', // Mostrar distancia en km
            ),
          );
        });

        // Mover la cámara a la nueva posición
        _moverCamara(newPosition);
      });
    } else {
      _timer
          ?.cancel(); // Cancelar el temporizador cuando se detiene el registro
      _locationTimer?.cancel();
    }
  }

  // Finalizar el registro de la ruta
  void _finalizarRegistro() {
    if (_isRecording) {
      _timer?.cancel();
      _locationTimer?.cancel();
      setState(() {
        _isRecording = false;
      });
    }
  }

  // Mostrar la pantalla para agregar detalles de la ruta
  void _mostrarPantallaFormulario() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RutaFormPage(
          routeCoords: _routeCoords, // Pasamos las coordenadas aquí
          distanceTraveled:
              _distanceTraveled, // Pasar distancia total recorrida
          secondsElapsed: _seconds, // Pasar tiempo transcurrido
          onSave: (rutaData) {
            _finalizarRegistro(); // Finalizar el registro
            rutaData['puntos'] =
                convertirAFormato(_routeCoords); // Convertir coordenadas
            postRuta(rutaData); // Enviar la ruta al backend
            Navigator.of(context).pop(); // Volver al mapa
          },
          onCancel: () {
            Navigator.of(context).pop(); // Volver al mapa sin guardar
          },
        ),
      ),
    );
  }

  // Mostrar un diálogo de confirmación antes de finalizar la ruta
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
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _finalizarRegistro(); // Finalizar el registro
                Navigator.of(context).pop(); // Cerrar el diálogo
                _mostrarPantallaFormulario(); // Mostrar el formulario
              },
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  // Formatear el tiempo en formato hh:mm:ss
  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Formatear la distancia para mostrar metros o kilómetros
  String _formatDistance(double distance) {
    if (distance < 1000) {
      return '${distance.toStringAsFixed(2)} m'; // Si es menor a 1 km, mostrar en metros
    } else {
      return '${(distance / 1000).toStringAsFixed(2)} km'; // Mostrar en kilómetros
    }
  }

  // Construir la interfaz gráfica de la página principal del mapa
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ruta test'),
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [
          // Mostrar un cargador mientras se obtiene la posición
          _initialPosition == null
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition!,
                    zoom: 18,
                  ),
                  markers: _markers.values.toSet(),
                  polylines: {_routePolyline},
                ),
          // Mostrar tiempo y distancia en la parte superior
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
          // Botón para centrar la cámara en la posición actual
          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              onPressed: _centrarEnPosicionActual,
              child: const Icon(Icons.my_location),
            ),
          ),
          // Botón para iniciar o finalizar el registro
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _isRecording
                  ? _mostrarConfirmacionFinalizar
                  : _iniciarRegistro,
              child: Text(_isRecording ? 'Guardar Ruta' : 'Iniciar Registro'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
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
  final List<LatLng> routeCoords; // Recibir las coordenadas
  final double distanceTraveled; // Distancia recorrida
  final int secondsElapsed; // Tiempo transcurrido
  final Function(Map<String, dynamic>)
      onSave; // Función que se ejecuta al guardar
  final VoidCallback onCancel; // Función que se ejecuta al cancelar

  const RutaFormPage({
    required this.routeCoords,
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
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  String _nombre = ''; // Nombre de la ruta
  String _descripcion = ''; // Descripción de la ruta
  String _dificultad = 'facil'; // Dificultad de la ruta

  @override
  Widget build(BuildContext context) {
    // Convertir los segundos a horas decimales para el tiempo estimado
    double _tiempoEstimado = widget.secondsElapsed / 3600;
    // Convertir la distancia a kilómetros
    double _distancia = widget.distanceTraveled / 1000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Detalles de la Ruta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // Asociar el formulario a la clave
          child: Column(
            children: [
              // Campo para el nombre de la ruta
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
              // Campo para la descripción de la ruta
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
              // Menú desplegable para seleccionar la dificultad de la ruta
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Dificultad'),
                value: _dificultad,
                items: const [
                  DropdownMenuItem(value: 'facil', child: Text('Fácil')),
                  DropdownMenuItem(value: 'mediano', child: Text('Mediano')),
                  DropdownMenuItem(value: 'dificil', child: Text('Difícil')),
                ],
                onChanged: (value) {
                  setState(() {
                    _dificultad = value!;
                  });
                },
              ),
              // Mostrar distancia calculada
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('Distancia: ${_distancia.toStringAsFixed(2)} km'),
              ),
              // Mostrar tiempo estimado calculado
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                    'Tiempo estimado: ${_tiempoEstimado.toStringAsFixed(2)} horas'),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Botón para guardar la ruta
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        Map<String, dynamic> rutaData = {
                          "nombre": _nombre,
                          "descripcion": _descripcion,
                          "dificultad": _dificultad,
                          "distancia_km": _distancia,
                          "tiempo_estimado_horas": _tiempoEstimado,
                          "puntos": convertirAFormato(
                              widget.routeCoords), // Agregar los puntos
                        };

                        widget.onSave(rutaData); // Enviar los datos
                      }
                    },
                    child: const Text('Guardar Ruta'),
                  ),
                  // Botón para cancelar y volver al mapa
                  ElevatedButton(
                    onPressed: widget.onCancel,
                    child: const Text('Cancelar'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
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
