import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config.dart'; // Asegúrate de que esta ruta esté correcta para cargar la configuración adecuada
import 'inicio.dart'; // Pantalla a la que navegas si el login es exitoso
import 'olvidarContra.dart'; // Pantalla de recuperación de contraseña
import 'registro.dart'; // Pantalla de registro
import 'package:itrek_maps/DataBase/bd_itrek.dart'; // Manejo de la base de datos SQLite

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Controlador para manejar la animación
  late Animation<double> _animation; // Animación que se aplicará al texto

  // Controladores de texto para capturar el nombre de usuario y la contraseña
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Variable que indica si la app está en estado de carga (muestra un spinner)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Inicialización de la animación
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // Duración de 2 segundos para la animación
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward(); // Inicia la animación cuando la pantalla aparece
  }

  @override
  void dispose() {
    // Libera los recursos cuando la pantalla se cierra
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Función que maneja el proceso de login
  Future<void> _login() async {
    final String username = _usernameController.text; // Obtiene el texto del nombre de usuario
    final String password = _passwordController.text; // Obtiene el texto de la contraseña

    // Muestra el spinner mientras se realiza la solicitud de autenticación
    setState(() {
      _isLoading = true;
    });

    // URL de la API de login
    final url = Uri.parse('$BASE_URL/api/login/'); // Cambia BASE_URL a tu backend
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username, // Envía el nombre de usuario al backend
        'password': password, // Envía la contraseña al backend
      }),
    );

    // Oculta el spinner después de recibir la respuesta del servidor
    setState(() {
      _isLoading = false;
    });

    // Si el código de respuesta es 200 (autenticación exitosa)
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body); // Decodifica la respuesta JSON
      final token = jsonData['token']; // El token es el valor clave a verificar
      final dbHelper = DatabaseHelper.instance;

      // Verifica si el token no es nulo
      if (token != null) {
        print("Token recibido: $token"); // Depuración: Imprime el token recibido

        // Guardar el token en la base de datos local (SQLite)
        await dbHelper.updateUserToken(username, token);

        // Navega a la pantalla de inicio `MenuScreen` reemplazando la pantalla actual
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MenuScreen()), // Verifica que `MenuScreen` esté importado y sea accesible
        );
      } else {
        // Si no se recibió el token, muestra un error
        print("No se recibió token");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error en la autenticación. Token no recibido.')),
        );
      }
    } else {
      // Si la autenticación falla (código diferente a 200), muestra un mensaje de error
      print("Error en la autenticación");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error en la autenticación')),
      );
    }
  }

  // Construcción del widget principal (pantalla de login)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF50C2C9), // Color del AppBar
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Verifica que el logo esté en assets
              height: 30, // Tamaño del logo
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animación del texto "Bienvenido a iTrek"
          FadeTransition(
            opacity: _animation, // Aplica la animación al texto
            child: const Text(
              'Bienvenido a iTrek',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Imagen centrada
          Center(
            child: Image.asset(
              'assets/images/maps-green.png', // Verifica que la imagen exista en assets
              height: 200, // Tamaño de la imagen
            ),
          ),
          const SizedBox(height: 60),

          // Campos del formulario de login (usuario y contraseña)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                // Campo para el nombre de usuario
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Usuario',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),
                // Campo para la contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: true, // Oculta el texto para las contraseñas
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),

          // Botones de acción (Ingresar, Registrarse y Olvidar Contraseña)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Muestra un spinner si está en estado de carga
                _isLoading
                    ? const CircularProgressIndicator() // Spinner de carga
                    : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50C2C9),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: _login, // Llama a la función _login cuando se presiona el botón
                  child: const Text('Ingresar'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50C2C9),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const RegistroScreen()), // Navega a la pantalla de registro
                    );
                  },
                  child: const Text('Registrarse'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                          const RecuperarContrasenaScreen()), // Navega a la pantalla de recuperación de contraseña
                    );
                  },
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
