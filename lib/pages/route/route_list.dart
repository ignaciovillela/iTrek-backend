import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:itrek/helpers/numbers.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/route/route_detail.dart';
import 'package:latlong2/latlong.dart';
import 'package:itrek/helpers/db.dart';
import 'package:diacritic/diacritic.dart';

enum Filtro { todas, locales, misRutas }

class ListadoRutasScreen extends StatefulWidget {
  const ListadoRutasScreen({super.key});

  @override
  _ListadoRutasScreenState createState() => _ListadoRutasScreenState();
}

class _ListadoRutasScreenState extends State<ListadoRutasScreen> {
  List<dynamic>? rutasGuardadas;
  List<dynamic>? rutasFiltradas;
  List<dynamic>? rutasLocales;

  Filtro filtroSeleccionado = Filtro.todas;

  String? _filtroDificultad;
  String _filtroNombre = '';
  int? _filtroEstrellas;

  bool _mostrarFiltroNombre = false;
  final List<String> _dificultades = ['Fácil', 'Moderada', 'Difícil'];

  late String myUsername;
  bool _isLoading = true; // Nueva bandera para controlar el estado de carga

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    myUsername = await db.values.get(db.values.username) ?? '';
    await _fetchRutas();
    setState(() {
      _isLoading = false; // Indicar que los datos ya están cargados
    });
  }

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

    switch (filtroSeleccionado) {
      case Filtro.locales:
        rutas = rutasLocales;
        break;
      case Filtro.misRutas:
        rutas = rutas?.where((ruta) => ruta['usuario']['username'] == myUsername).toList();
        break;
      case Filtro.todas:
      default:
      // No se aplica filtro adicional
        break;
    }

    if (_filtroDificultad != null && _filtroDificultad!.isNotEmpty) {
      String filtroNormalizado = removeDiacritics(_filtroDificultad!.toLowerCase().trim());
      rutas = rutas?.where((ruta) {
        String rutaDificultad = removeDiacritics(ruta['dificultad'].toString().toLowerCase().trim());
        return rutaDificultad == filtroNormalizado;
      }).toList();
    }
    if (_filtroNombre.isNotEmpty) {
      rutas = rutas?.where((ruta) => ruta['nombre'].toString().toLowerCase().contains(_filtroNombre.toLowerCase())).toList();
    }
    if (_filtroEstrellas != null) {
      rutas = rutas?.where((ruta) {
        if (ruta['puntaje'] != null) {
          final estrellasRuta = ruta['puntaje'];
          return _filtroEstrellas! <= estrellasRuta && estrellasRuta < _filtroEstrellas! + 1;
        }
        return false;
      }).toList();
    }

    setState(() {
      rutasFiltradas = rutas;
    });
  }

  // Widget para los filtros "Todas" y "Locales"
  Widget _buildFiltroButton({required String label, required Filtro filtro}) {
    final bool isSelected = filtroSeleccionado == filtro;

    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: () {
          setState(() {
            filtroSeleccionado = filtro;
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
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltrosPrincipales() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFiltroButton(label: 'Todas', filtro: Filtro.todas),
          const SizedBox(width: 8),
          _buildFiltroButton(label: 'Sin conexión', filtro: Filtro.locales),
          const SizedBox(width: 8),
          _buildFiltroButton(label: 'Mis rutas', filtro: Filtro.misRutas),
        ],
      ),
    );
  }

  // Widget para los filtros adicionales: Dificultad, Nombre, Estrellas
  Widget _buildFiltrosAdicionales() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
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
          points.addAll(
            jsonResponse['puntos']
                .map<LatLng>((punto) => LatLng(punto['latitud'], punto['longitud']))
                .toList(),
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
          final ruta = rutasFiltradas![index];
          return _buildRutaCard(ruta);
        },
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Listado de Rutas'),
      body: Column(
        children: [
          Expanded(
            flex: 0,
            child: Column(
              children: [
                _buildFiltrosPrincipales(),
                _buildFiltrosAdicionales(),
              ],
            ),
          ),
          Expanded(child: bodyContent),
        ],
      ),
    );
  }

  Widget _buildRutaCard(dynamic ruta) {
    final bool esLocal = ruta['local'] == 1;
    final double puntaje = (ruta['puntaje'] as num?)?.toDouble() ?? 0.0;
    final String puntajeDisplay = puntaje > 0 ? conDecimales.format(puntaje) : '---';

    return Card(
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 5,
      color: esLocal ? Colors.green.shade50 : null,
      child: ListTile(
        title: Text(
          ruta['nombre'],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ruta['descripcion']),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dificultad: ${ruta['dificultad']}'),
                Text('Creador: ${ruta['usuario']['username']}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ],
        ),
        leading: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.map, color: Color(0xFF50C9B5)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(puntajeDisplay, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(width: 2),
                const Icon(Icons.star, size: 17, color: Colors.amber),
              ],
            ),
          ],
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
  }
}
