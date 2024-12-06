import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:itrek/helpers/config.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/img.dart';
import 'package:itrek/helpers/numbers.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/auth/login.dart';
import 'package:itrek/pages/activity_registry.dart';
import 'package:itrek/pages/route/route_list.dart';
import 'package:itrek/pages/route/route_register.dart';
import 'package:itrek/pages/user/user_profile.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? userStats;

  // Método para verificar si el token está almacenado
  Future<bool> _checkToken() async {
    String? tokenData = await db.values.get(db.values.token);
    print('Token encontrado: $tokenData');
    return tokenData != null;
  }

  // Método para obtener estadísticas del usuario
  Future<void> _fetchAndSetUserStats() async {
    await makeRequest(
      method: GET,
      url: LOGIN_CHECK,
      onOk: (response) {
        final responseData = jsonDecode(response.body);
        print('Datos recibidos: $responseData');
        setState(() {
          userStats = responseData;
        });
      },
      onError: (response) {
        print('Error al obtener estadísticas: ${response.statusCode}');
        print('Mensaje de error: ${response.body}');
        setState(() {
          userStats = {
            'nombre_nivel': 'Error',
            'puntos_trek': 0,
            'descripcion_nivel': 'No se pudieron cargar los datos del usuario.',
          };
        });
      },
      onConnectionError: (errorMessage) {
        print('Error de conexión: $errorMessage');
        setState(() {
          userStats = {
            'nombre_nivel': 'Error de Conexión',
            'puntos_trek': 0,
            'descripcion_nivel': 'No se pudo establecer una conexión con el servidor.',
          };
        });
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
                      if (userStats != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: screenWidth * 0.3,
                                  child: Image.network(
                                    '$BASE_URL${userStats?['imagen_perfil'] ?? '/static/default_profile.jpg'}',
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${userStats?['nombre_nivel'] ?? 'Cargando...'}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Días trekkeando: ${sinDecimales.format(userStats?['dias_creacion_cuenta'] ?? 0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Distancia recorrida: ${formatDistancia(userStats?['distancia_trek'])} km',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tiempo total: ${formatTiempo(userStats?['minutos_trek'] ?? 0)}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Puntos trek: ${sinDecimales.format(userStats?['puntos_trek'] ?? 0)}',
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
                              userStats?['descripcion_nivel'] ?? '',
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
                            label: 'Registrar Ruta',
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
                              await _fetchAndSetUserStats();
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
                            label: 'Mi Actividad',
                            icon: Icons.people,
                            iconColor: Colors.purple,
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                  const ActivtyScreen(),
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
