import 'package:flutter/material.dart';

import 'comunidad.dart'; // Importa la pantalla de comunidad
import 'listadoRutas.dart'; // Importamos la pantalla de listado de rutas
import 'maps_google.dart'; // Importamos la pantalla del mapa
import 'perfil.dart'; // Importa la pantalla de perfil

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF50C9B5), // Color de fondo del AppBar
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Asegúrate de que el logo esté en la carpeta assets
              height: 30, // Tamaño pequeño del logo
            ),
            const SizedBox(width: 10), // Espacio entre el logo y el texto
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
          const SizedBox(height: 40), // Espacio para bajar el contenido

          // Texto que dice "Menú"
          const Text(
            'Menú',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 20), // Espacio debajo del texto

          // Imagen desde assets en la parte superior central
          Center(
            child: Image.asset(
              'assets/images/trek.png', // Asegúrate de que la imagen esté en assets
              height: 120, // Tamaño de la imagen
            ),
          ),

          const SizedBox(height: 50), // Espacio debajo de la imagen

          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount:
                      2, // Número de columnas (2 para formar un cuadrado)
                  crossAxisSpacing: 15.0, // Menor espacio entre columnas
                  mainAxisSpacing: 15.0, // Menor espacio entre filas
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF50C9B5), // Color del botón
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Bordes redondeados
                        ),
                        padding:
                            const EdgeInsets.all(10), // Botones más compactos
                      ),
                      onPressed: () {
                        // Navega a la pantalla del mapa al presionar el botón "Iniciar Ruta"
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GoogleMapsPage()),
                        );
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/maps-green.png', // Imagen asociada al botón
                            height: 120, // Tamaño ajustado de la imagen
                          ),
                          const SizedBox(
                              height: 10), // Espacio entre imagen y texto
                          const Text('Iniciar Ruta'),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF50C9B5), // Color del botón
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Bordes redondeados
                        ),
                        padding:
                            const EdgeInsets.all(10), // Botones más compactos
                      ),
                      onPressed: () {
                        // Navega a la pantalla de perfil
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
                            'assets/images/perfil.png', // Imagen asociada al botón
                            height: 120, // Tamaño ajustado de la imagen
                          ),
                          const SizedBox(
                              height: 10), // Espacio entre imagen y texto
                          const Text('Perfil'),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF50C9B5), // Color del botón
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Bordes redondeados
                        ),
                        padding:
                            const EdgeInsets.all(10), // Botones más compactos
                      ),
                      onPressed: () {
                        // Navega a la pantalla de listado de rutas
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
                            'assets/images/listado.png', // Imagen asociada al botón
                            height: 120, // Tamaño ajustado de la imagen
                          ),
                          const SizedBox(
                              height: 10), // Espacio entre imagen y texto
                          const Text('Listado de Rutas'),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF50C9B5), // Color del botón
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10), // Bordes redondeados
                        ),
                        padding:
                            const EdgeInsets.all(10), // Botones más compactos
                      ),
                      onPressed: () {
                        // Navega a la pantalla de comunidad
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
                            'assets/images/com.png', // Imagen asociada al botón
                            height: 120, // Tamaño ajustado de la imagen
                          ),
                          const SizedBox(
                              height: 10), // Espacio entre imagen y texto
                          const Text('Comunidad'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40), // Más espacio para bajar los botones
        ],
      ),
    );
  }
}
