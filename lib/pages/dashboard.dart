import 'package:flutter/material.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/img.dart';
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
  Future<bool> _checkToken() async {
    String? tokenData = await db.values.get(db.values.token);
    return tokenData != null;
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: screenWidth * 0.3,
                            child: Image.asset(
                              'assets/images/trek.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Nivel: Avanzado',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Trekking realizados: 25',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Próxima ruta: Torres del Paine',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
