import 'package:flutter/material.dart';
import 'inicio.dart'; // Asegúrate de que el archivo inicio.dart esté en el mismo directorio o indica la ruta correcta.
import 'registro.dart'; // Importa la pantalla de registro.
import 'olvidarContra.dart'; // Importa la pantalla de recuperación de contraseña.

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pantalla de Login'),
      ),
      body: Column(
        children: [
          // Espacio flexible para empujar el formulario hacia el centro vertical
          const Spacer(flex: 2),

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
                const SizedBox(
                    height: 40), // Aumentado el espacio entre los campos

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

          // Más espacio flexible para mantener el formulario centrado verticalmente
          const Spacer(flex: 1),

          // Sección de botones en la parte inferior
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Botón de ingresar
                ElevatedButton(
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
                TextButton(
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
