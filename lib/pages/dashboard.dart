import 'package:flutter/material.dart';
import 'package:itrek/db/db.dart';
import 'package:itrek/pages/comunidad.dart';
import 'package:itrek/pages/login/login.dart';
import 'package:itrek/pages/ruta/rutaListar.dart';
import 'package:itrek/pages/ruta/rutaRegistrar.dart';
import 'package:itrek/pages/usuarioPerfil.dart';


class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  // Método para verificar si el token existe en la tabla `valores`
  Future<bool> _checkToken() async {
    // Busca en la base de datos si existe un token almacenado bajo la clave 'token'
    Object? tokenData = await db.get(db.token);

    // Si encuentra un token, el usuario está autenticado
    return tokenData != null;
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
                FutureBuilder<Object?>(
                  future: db.get(db.username), // Llama a la función asíncrona
                  builder: (BuildContext context, AsyncSnapshot<Object?> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator(); // Muestra un indicador de carga mientras espera
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else if (!snapshot.hasData || snapshot.data == null) {
                      return const Text(
                        'No data available',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      );
                    } else {
                      final username = snapshot.data.toString();
                      return Text(
                        'Hola, $username', // Muestra el valor obtenido de la DB
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 20),
                Center(
                  child: Image.asset(
                    'assets/images/trek.png',
                    height: 118,
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
                                    builder: (context) => const RegistrarRuta()),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/maps-green.png',
                                  height: 118,
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
                                    builder: (context) => const PerfilUsuarioScreen()),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/perfil.png',
                                  height: 118,
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
                                    builder: (context) => const ListadoRutasScreen()),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/listado.png',
                                  height: 118,
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
                                  height: 118,
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
