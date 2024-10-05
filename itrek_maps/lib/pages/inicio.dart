import 'package:flutter/material.dart';
import 'maps_google.dart'; // Importamos la pantalla del mapa
import 'listadoRutas.dart'; // Importamos la pantalla de listado de rutas
import 'perfil.dart'; // Importa la pantalla de perfil
import 'comunidad.dart'; // Importa la pantalla de comunidad

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menú Principal'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.all(20.0),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount:
                      2, // Número de columnas (2 para formar un cuadrado)
                  crossAxisSpacing: 20.0, // Espacio entre columnas
                  mainAxisSpacing: 20.0, // Espacio entre filas
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              0), // Sin bordes redondeados
                        ),
                      ),
                      onPressed: () {
                        // Navega a la pantalla del mapa al presionar el botón "Iniciar Ruta"
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const GoogleMapsPage()),
                        );
                      },
                      child: const Text('Iniciar Ruta'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              0), // Sin bordes redondeados
                        ),
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
                      child: const Text('Perfil'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              0), // Sin bordes redondeados
                        ),
                      ),
                      onPressed: () {
                        // Navega a la pantalla de listado de rutas al presionar el botón
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ListadoRutasScreen()),
                        );
                      },
                      child: const Text('Listado de Rutas'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              0), // Sin bordes redondeados
                        ),
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
                      child: const Text('Comunidad'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
