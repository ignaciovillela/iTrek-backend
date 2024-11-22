import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:itrek/helpers/config.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/img.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/auth/login.dart';
import 'package:itrek/pages/comunity.dart';
import 'package:itrek/pages/route/route_list.dart';
import 'package:itrek/pages/route/route_register.dart';
import 'package:itrek/pages/user/user_profile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? nombreNivel;
  int? diasTrek;
  double? distanciaTrek;
  int? minutosTrek;
  int? puntosTrek;
  String? descripcionNivel;

  // Método para verificar si el token está almacenado
  Future<bool> _checkToken() async {
    String? tokenData = await db.values.get(db.values.token);
    print('Token encontrado: $tokenData');
    return tokenData != null;
  }

  // Método para guardar datos individuales en la base de datos local
  Future<void> _saveUserStatsLocally(Map<String, dynamic> stats) async {
    await db.values.create('nombre_nivel', stats['nombre_nivel']);
    await db.values.create('dias_trek', stats['dias_creacion_cuenta'].toString());
    await db.values.create('distancia_trek', stats['distancia_trek'].toString());
    await db.values.create('minutos_trek', stats['minutos_trek'].toString());
    await db.values.create('puntos_trek', stats['puntos_trek'].toString());
    await db.values.create('descripcion_nivel', stats['descripcion_nivel']);
  }

  // Método para cargar datos individuales desde la base de datos local
  Future<void> _loadUserStatsLocally() async {
    String? nombreNivelLocal = await db.values.get('nombre_nivel');
    String? diasTrekLocal = await db.values.get('dias_trek');
    String? distanciaTrekLocal = await db.values.get('distancia_trek');
    String? minutosTrekLocal = await db.values.get('minutos_trek');
    String? puntosTrekLocal = await db.values.get('puntos_trek');
    String? descripcionNivelLocal = await db.values.get('descripcion_nivel');

    setState(() {
      nombreNivel = nombreNivelLocal;
      diasTrek = int.tryParse(diasTrekLocal ?? '0');
      distanciaTrek = double.tryParse(distanciaTrekLocal ?? '0.0');
      minutosTrek = int.tryParse(minutosTrekLocal ?? '0');
      puntosTrek = int.tryParse(puntosTrekLocal ?? '0');
      descripcionNivel = descripcionNivelLocal;
    });
  }

  // Método para obtener estadísticas del usuario
  Future<void> _fetchAndSetUserStats() async {
    // Cargar datos locales antes de realizar la solicitud a la API
    await _loadUserStatsLocally();

    // Intentar obtener los datos más recientes de la API
    await makeRequest(
      method: GET,
      url: LOGIN_CHECK,
      onOk: (response) async {
        final responseData = jsonDecode(response.body);
        print('Datos recibidos: $responseData');

        setState(() {
          nombreNivel = responseData['nombre_nivel'];
          diasTrek = responseData['dias_creacion_cuenta'];
          distanciaTrek = responseData['distancia_trek'];
          minutosTrek = responseData['minutos_trek'];
          puntosTrek = responseData['puntos_trek'];
          descripcionNivel = responseData['descripcion_nivel'];
        });

        // Guardar los datos obtenidos en la base de datos local
        await _saveUserStatsLocally(responseData);
      },
      onError: (response) {
        print('Error al obtener estadísticas: ${response.statusCode}');
        print('Mensaje de error: ${response.body}');
      },
      onConnectionError: (errorMessage) {
        print('Error de conexión: $errorMessage');
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchAndSetUserStats();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<bool>(
      future: _checkToken(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data == true) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: colorScheme.primary,
              title: Row(
                children: [
                  logoWhite,
                  const SizedBox(width: 10),
                  const Text(
                    'iTrek',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String?>(
                        future: db.values.get(db.values.first_name),
                        builder: (context, snapshot) {
                          String userName = snapshot.data ?? 'Admin';
                          return Text(
                            'Hola, $userName',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      if (nombreNivel != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: screenWidth * 0.3,
                                  child: Image.network(
                                    '$BASE_URL/static/default_profile.jpg',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$nombreNivel',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Días trekkeando: $diasTrek',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Distancia recorrida: ${distanciaTrek?.toStringAsFixed(2)} km',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Minutos totales: $minutosTrek',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Puntos acumulados: $puntosTrek',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              descripcionNivel ?? '',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        )
                      else
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                      const SizedBox(height: 40),
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 15.0,
                        mainAxisSpacing: 15.0,
                        children: [
                          DashboardCircleButton(
                            label: 'Iniciar Ruta',
                            icon: Icons.directions_walk,
                            iconColor: Colors.green,
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegistrarRuta(),
                                ),
                              );
                            },
                          ),
                          DashboardCircleButton(
                            label: 'Perfil',
                            icon: Icons.person,
                            iconColor: Colors.blue,
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const PerfilUsuarioScreen(),
                                ),
                              );
                              setState(() {});
                            },
                          ),
                          DashboardCircleButton(
                            label: 'Listado de Rutas',
                            icon: Icons.map,
                            iconColor: Colors.orange,
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const ListadoRutasScreen(),
                                ),
                              );
                            },
                          ),
                          DashboardCircleButton(
                            label: 'Comunidad',
                            icon: Icons.people,
                            iconColor: Colors.purple,
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const RutasCompartidasScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                );
              },
            ),
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
