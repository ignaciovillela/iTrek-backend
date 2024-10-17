import 'package:flutter/material.dart';

import '../dashboard.dart'; // Asegúrate de que el archivo dashboard.dart esté en el mismo directorio o indica la ruta correcta.
import 'loginCuentaRecuperar.dart'; // Importa la pantalla de recuperación de contraseña.
import 'loginRegistrar.dart'; // Importa la pantalla de registro.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward(); // Inicia la animación automáticamente
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF50C2C9), // Color del AppBar
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
        mainAxisAlignment:
            MainAxisAlignment.center, // Centra el contenido verticalmente
        children: [
          // Animación de texto "Bienvenido a iTrek"
          FadeTransition(
            opacity: _animation,
            child: const Text(
              'Bienvenido a iTrek',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20), // Espacio entre el texto y la imagen

          // Imagen centrada horizontal y verticalmente
          Center(
            child: Image.asset(
              'assets/images/maps-green.png', // Asegúrate de que la imagen esté en la carpeta assets
              height: 200, // Tamaño de la imagen
            ),
          ),

          const SizedBox(height: 60), // Espacio grande para bajar los campos

          // Formulario centrado
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Campo de nombre de usuario
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Usuario',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40), // Espacio entre los campos

                // Campo de contraseña
                TextFormField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40), // Espacio entre el campo y el botón
              ],
            ),
          ),

          // Sección de botones en la parte inferior
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botón de ingresar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF50C2C9), // Color del botón de ingresar
                    padding: const EdgeInsets.symmetric(
                        vertical: 15), // Tamaño del botón
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    // Navega a la pantalla de inicio cuando se presiona el botón
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MenuScreen()),
                    );
                  },
                  child: const Text('Ingresar'),
                ),
                const SizedBox(height: 10), // Espacio entre los botones

                // Botón de registrarse
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xFF50C2C9), // Color del botón de registrarse
                    padding: const EdgeInsets.symmetric(
                        vertical: 15), // Tamaño del botón
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    // Navega a la pantalla de registro cuando se presiona el botón
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegistroScreen()),
                    );
                  },
                  child: const Text('Registrarse'),
                ),
                const SizedBox(height: 10), // Espacio entre los botones

                // Botón de olvido contraseña
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue, // Color azul para destacar
                    padding: const EdgeInsets.symmetric(
                        vertical: 15), // Tamaño del botón
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    // Navega al formulario de recuperación de contraseña
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const RecuperarContrasenaScreen()),
                    );
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
          ),

          const SizedBox(
              height: 20), // Pequeño espacio antes del borde inferior
        ],
      ),
    );
  }
}
