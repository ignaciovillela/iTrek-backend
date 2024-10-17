import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:itrek_maps/DataBase/bd_itrek.dart'; // Asegúrate de tener la ruta correcta de la clase DatabaseHelper

import 'comunidad.dart'; // Importa la pantalla de comunidad
import 'listadoRutas.dart'; // Importamos la pantalla de listado de rutas
import 'maps_google.dart'; // Importamos la pantalla del mapa
import 'perfil.dart'; // Importa la pantalla de perfil
import 'login.dart'; // Pantalla de login para redireccionar si no hay token

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  Future<bool> _checkToken() async {
    final dbHelper = DatabaseHelper.instance;
    // Busca en la base de datos si existe un usuario con un token válido
    List<Map<String, dynamic>> userWithToken = await dbHelper.getUserWithToken();

    // Si encuentra un usuario con token, el usuario está autenticado
    if (userWithToken.isNotEmpty) {
      return true; // Usuario autenticado
    } else {
      return false; // Usuario no autenticado
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkToken(), // Verifica el token antes de construir la interfaz
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data == true) {
          // Si el token es válido, muestra la pantalla de menú
          return Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF50C9B5),
              title: Row(
                children: [
                  Image.asset(
                    'assets/images/logo.png', // Asegúrate de que el logo esté en la carpeta assets
                    height: 30,
                  ),
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
            body: Column(
              children: [
                const SizedBox(height: 40),
                const Text(
                  'Menú',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/images/trek.png',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 50),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: GridView.count(
                        shrinkWrap: true,
                        crossAxisCount: 2,
                        crossAxisSpacing: 15.0,
                        mainAxisSpacing: 15.0,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF50C9B5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(10),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const GoogleMapsPage()),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/maps-green.png',
                                  height: 120,
                                ),
                                const SizedBox(height: 10),
                                const Text('Iniciar Ruta'),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF50C9B5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(10),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const PerfilUsuarioScreen()),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/perfil.png',
                                  height: 120,
                                ),
                                const SizedBox(height: 10),
                                const Text('Perfil'),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF50C9B5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(10),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const ListadoRutasScreen()),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/listado.png',
                                  height: 120,
                                ),
                                const SizedBox(height: 10),
                                const Text('Listado de Rutas'),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF50C9B5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.all(10),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const RutasCompartidasScreen()),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/com.png',
                                  height: 120,
                                ),
                                const SizedBox(height: 10),
                                const Text('Comunidad'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        } else {
          // Si no hay token, redirige al login
          return const LoginScreen();
        }
      },
    );
  }
}
