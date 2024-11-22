import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/route/route_detail.dart';
import 'package:latlong2/latlong.dart';
import 'package:itrek/helpers/db.dart';
import 'package:diacritic/diacritic.dart';

class ListadoRutasScreen extends StatefulWidget {
  const ListadoRutasScreen({super.key});

  @override
  _ListadoRutasScreenState createState() => _ListadoRutasScreenState();
}

class _ListadoRutasScreenState extends State<ListadoRutasScreen> {
  List<dynamic>? rutasGuardadas;
  List<dynamic>? rutasFiltradas;
  List<dynamic>? rutasLocales;
  bool mostrarRutasLocales = false;

  // Variables para los filtros
  String? _filtroDificultad;
  String _filtroNombre = '';
  int? _filtroEstrellas;

  // Controla la visibilidad del campo de texto del filtro de nombre
  bool _mostrarFiltroNombre = false;

  // Opciones de dificultad
  final List<String> _dificultades = ['Fácil', 'Moderada', 'Difícil'];

  @override
  void initState() {
    super.initState();
    _fetchRutas();
  }

  // Función para obtener las rutas desde la API.
  Future<void> _fetchRutas() async {
    rutasLocales = await db.routes.getLocalRoutes();

    await makeRequest(
      method: GET,
      url: ROUTES,
      onOk: (response) {
        setState(() {
          rutasGuardadas = jsonDecode(response.body);
          _aplicarFiltro();
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
    List<dynamic>? rutas = rutasGuardadas;

    if (mostrarRutasLocales) {
      rutas = rutas?.where((ruta) => ruta['local'] == true).toList();
    }

    if (_filtroDificultad != null && _filtroDificultad!.isNotEmpty) {
      String filtroNormalizado = removeDiacritics(_filtroDificultad!.toLowerCase().trim());
      print('Filtrando por dificultad (normalizado): $filtroNormalizado');
      rutas = rutas?.where((ruta) {
        String rutaDificultad = removeDiacritics(ruta['dificultad'].toString().toLowerCase().trim());
        print('Ruta dificultad (normalizado): $rutaDificultad');
        return rutaDificultad == filtroNormalizado;
      }).toList();
    }
    if (_filtroNombre.isNotEmpty) {rutas = rutas?.where((ruta) => ruta['nombre'].toString().toLowerCase().contains(_filtroNombre.toLowerCase())).toList();
    }
    if (_filtroEstrellas != null) {
      rutas = rutas?.where((ruta) {
        if (ruta['puntaje'] != null) {
          final estrellasRuta = ruta['puntaje'];
          return _filtroEstrellas! <= estrellasRuta && estrellasRuta < _filtroEstrellas!+1;
        }
        return false;
      }).toList();
    }

    setState(() {
      rutasFiltradas = rutas;
    });
  }

  // Widget para los filtros "Todas" y "Locales"
  Widget _buildFiltrosPrincipales() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Filtro "Todas"
          SizedBox(
            height: 40, // Asegura que el SizedBox tenga un tamaño uniforme
            child: TextButton(
              onPressed: () {
                setState(() {
                  mostrarRutasLocales = false;
                  _aplicarFiltro();
                  print('Seleccionado: Todas');
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: !mostrarRutasLocales ? Colors.blue : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                minimumSize: const Size(80, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Todas',
                style: TextStyle(
                  fontWeight: !mostrarRutasLocales ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filtro "Locales"
          SizedBox(
            height: 40, // Asegura que el SizedBox tenga un tamaño uniforme
            child: TextButton(
              onPressed: () {
                setState(() {
                  mostrarRutasLocales = true;
                  _aplicarFiltro();
                  print('Seleccionado: Locales');
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: mostrarRutasLocales ? Colors.blue : Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                minimumSize: const Size(80, 40),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Locales',
                style: TextStyle(
                  fontWeight: mostrarRutasLocales ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para los filtros adicionales: Dificultad, Nombre, Estrellas
  Widget _buildFiltrosAdicionales() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtros de Dificultad
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                'Dificultad: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              // Filtro de Dificultad
              Wrap(
                spacing: 8.0,
                children: _dificultades.map((dificultad) {
                  bool isSelected = _filtroDificultad == dificultad;
                  return SizedBox(
                    height: 40,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          if (isSelected) {
                            _filtroDificultad = null; // Deseleccionar si ya está seleccionado
                            print('Deseleccionando dificultad: $dificultad');
                          } else {
                            _filtroDificultad = dificultad;
                            print('Seleccionando dificultad: $dificultad');
                          }
                          _aplicarFiltro();
                        });
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: isSelected ? Colors.blue : Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        minimumSize: const Size(80, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        dificultad,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 13),
          // Filtro de Estrellas y Lupa
          Row(
            children: [
              const Text(
                'Estrellas: ',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: Center(
                  child: SizedBox(
                    height: 30,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        int estrella = index + 1;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_filtroEstrellas == estrella) {
                                _filtroEstrellas = null;
                                print('Deseleccionando estrellas: $estrella');
                              } else {
                                _filtroEstrellas = estrella;
                                print('Seleccionando estrellas: $estrella');
                              }
                              _aplicarFiltro();
                            });
                          },
                          child: Icon(
                            Icons.star,
                            color: estrella <= (_filtroEstrellas ?? 0) ? Colors.amber : Colors.grey,
                            size: 24,
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
              // Icono de Lupa
              IconButton(
                icon: Icon(
                  _mostrarFiltroNombre ? Icons.close : Icons.search,
                  color: Colors.blue,
                ),
                onPressed: () {
                  setState(() {
                    _mostrarFiltroNombre = !_mostrarFiltroNombre;
                    if (!_mostrarFiltroNombre) {
                      _filtroNombre = '';
                      _aplicarFiltro();
                      print('Ocultando campo de filtro por nombre');
                    } else {
                      print('Mostrando campo de filtro por nombre');
                    }
                  });
                },
              ),
            ],
          ),
          // Campo de Texto para Filtrar por Nombre
          if (_mostrarFiltroNombre)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Filtrar por Nombre',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _mostrarFiltroNombre = false;
                        _filtroNombre = '';
                        _aplicarFiltro();
                        print('Limpiando y ocultando filtro por nombre');
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _filtroNombre = value;
                    _aplicarFiltro();
                    print('Filtrando por nombre: $value');
                  });
                },
              ),
            ),
        ],
      ),
    );
  }

  // Función para eliminar una ruta a través de la API.
  Future<void> _deleteRuta(int id) async {
    await makeRequest(
      method: DELETE,
      url: ROUTE_DETAIL,
      urlVars: {'id': id},
      onOk: (response) {
        setState(() {
          rutasGuardadas!.removeWhere((ruta) => ruta['id'] == id);
          _aplicarFiltro();
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
    final List<LatLng> points = [];

    await makeRequest(
      method: GET,
      url: ROUTE_DETAIL,
      urlVars: {'id': routeId},
      onOk: (response) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['puntos'] != null && jsonResponse['puntos'].isNotEmpty) {
          points.addAll(jsonResponse['puntos'].map<LatLng>((punto) => LatLng(punto['latitud'], punto['longitud'])).toList(),
          );
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

    return points;
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
            Text('Cargando rutas...', style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    } else if (rutasFiltradas!.isEmpty) {
      bodyContent = const Center(
        child: Text("No hay rutas para mostrar", style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    } else {
      bodyContent = ListView.builder(
        itemCount: rutasFiltradas!.length,
        itemBuilder: (context, index) {
          final ruta = rutasFiltradas![index];
          final bool esLocal = ruta['local'] == 1;
          final double puntaje = (ruta['puntaje'] as num?)?.toDouble() ?? 0.0;
          final String puntajeDisplay = puntaje > 0 ? puntaje.toStringAsFixed(1) : '---';

          return Card(
            margin: const EdgeInsets.all(8.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
            elevation: 5,
            color: esLocal ? Colors.green.shade50 : null,
            child: ListTile(
              title: Text(ruta['nombre'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ruta['descripcion']),
                  const SizedBox(height: 5),
                  Text('Dificultad: ${ruta['dificultad']}'),
                ],
              ),
              leading: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map, color: Color(0xFF50C9B5)),
                  const SizedBox(height: 4),
                  // Mostrar puntaje
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        puntajeDisplay,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.star,
                        size: 17,
                        color: Colors.amber,
                      ),
                    ],
                  ),
                ],
              ),
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
          // Responsivo
          Expanded(flex: 0, child: SingleChildScrollView(
              child: Column(children: [
                  _buildFiltrosPrincipales(), // Filtros "Todas" y "Locales"
                  _buildFiltrosAdicionales(), // Filtros de Dificultad, Nombre y Estrellas
                ],
              ),
            ),
          ),
          // Contenido principal que se expande
          Expanded(child: bodyContent),
        ],
      ),
    );
  }
}
