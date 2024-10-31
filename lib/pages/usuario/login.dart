import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:itrek/db.dart';
import 'package:itrek/pages/dashboard.dart';
import 'package:itrek/request.dart';
import 'package:itrek/pages/usuario/loginRegistrar.dart';
import 'package:itrek/pages/usuario/loginCuentaRecuperar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _hasUsername = false; // Para controlar si ya existe un username guardado
  String? _savedUsername; // Variable para almacenar el username guardado

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
    _controller.forward();

    _checkForSavedUsername(); // Verificar si ya existe un username guardado
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Método para verificar si ya existe un username guardado en la DB
  Future<void> _checkForSavedUsername() async {
    final username = await db.values.get(db.values.username); // Obtener el username de la DB
    if (username != null) {
      setState(() {
        _hasUsername = true;
        _savedUsername = username.toString(); // Guardar el username si existe
      });
    }
  }

  // Función que maneja el proceso de login
  Future<void> _login() async {
    final String username = _hasUsername ? _savedUsername! : _usernameController.text;
    final String password = _passwordController.text;

    if (password.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de usuario y la contraseña no pueden estar vacíos')),
      );
      return;
    }

    await makeRequest(
      method: POST,
      url: LOGIN,
      body: {'username': username, 'password': password},
      useToken: false,
      onOk: (response) async {
        final jsonData = jsonDecode(response.body);
        final token = jsonData['token'];

        if (token != null) {
          // Guardar el token y los datos del usuario en la base de datos
          await db.values.create(db.values.token, token);
          await db.values.create(db.values.username, username);
          await db.values.create('usuario_email', jsonData['email']);
          await db.values.create('usuario_first_name', jsonData['first_name']);
          await db.values.create('usuario_last_name', jsonData['last_name']);
          await db.values.create('usuario_biografia', jsonData['biografia']);
          await db.values.create('usuario_imagen_perfil', jsonData['imagen_perfil'] ?? '');

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MenuScreen()),
          );
        }
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error en la autenticación')),
        );
      },
      onConnectionError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error en la autenticación: $errorMessage')),
        );
      },
    );
  }
  // Función para manejar la navegación a la página de registro
  Future<void> _loginRegistrar() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroScreen()),
    );
  }
  // Función para manejar la navegación a la página de Recuperar Cuenta
  Future<void> _loginCuentaRecuperar() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecuperarContrasenaScreen()),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF50C2C9),
        title: Row(
          children: [
            // Aquí va el logo, si lo tienes
            const Text(
              'iTrek',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FadeTransition(
            opacity: _animation,
            child: const Text(
              'Bienvenido a iTrek',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
            ),
          ),
          const SizedBox(height: 20),
          // Aquí puedes agregar la imagen de tu aplicación
          const SizedBox(height: 60),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                if (!_hasUsername)
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de Usuario',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_hasUsername)
                  Text(
                    'Hola, $_savedUsername! Nos alegra verte de nuevo.\n'
                        'Por favor, ingresa tu clave para continuar.',
                    style: const TextStyle(fontSize: 15, color: Color(0xFF999999), fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF50C2C9),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: _login,
                    child: const Text('Ingresar'),
                  ),
                ),
                const SizedBox(height: 20), // Espacio de 20 píxeles entre los botones
                // Botón para Registrarse
                SizedBox(
                  width: double.infinity, // Ocupa el 100% del ancho disponible
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500), // Color naranja
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: _loginRegistrar,
                    child: const Text('Registrarse'),
                  ),
                ),
                const SizedBox(height: 20), // Espacio de 20 píxeles entre los botones
                // Botón para Recuperar Cuenta
                SizedBox(
                  width: double.infinity, // Ocupa el 100% del ancho disponible
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7F7F), // Color Rojo
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: _loginCuentaRecuperar,
                    child: const Text('Recuperar Cuenta'),
                  ),
                ),
                const SizedBox(height: 10),
                if (_hasUsername)
                  TextButton(
                    onPressed: _deleteSavedUsername,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '¿No eres $_savedUsername? Haz clic aquí para cambiar de cuenta.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Container(height: 1, color: Color(0xFFCCCCCC)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Método para borrar el username guardado
  Future<void> _deleteSavedUsername() async {
    await db.values.delete(db.values.username); // Borrar el username de la DB
    setState(() {
      _hasUsername = false; // Volver a mostrar el campo de username
      _savedUsername = null; // Limpiar el username guardado
    });
  }
}
