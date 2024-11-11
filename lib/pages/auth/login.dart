import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:itrek/db.dart';
import 'package:itrek/img.dart';
import 'package:itrek/pages/auth/login_recover.dart';
import 'package:itrek/pages/auth/login_register.dart';
import 'package:itrek/pages/dashboard.dart';
import 'package:itrek/request.dart';


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

  // Método para borrar el username guardado
  Future<void> _deleteSavedUsername() async {
    await db.values.delete(db.values.username); // Borrar el username de la DB
    setState(() {
      _hasUsername = false; // Volver a mostrar el campo de username
      _savedUsername = null; // Limpiar el username guardado
    });
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
        final data = jsonDecode(response.body);
        if (data['token'] != null) {
          await db.values.setUserData(data);

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
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
            logoWhite,
            const SizedBox(width: 10),
            const Text(
              'iTrek',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView( // Envuelve el contenido en un SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
              Center(
                child: Image.asset('assets/images/maps-green.png', height: 200),
              ),
              const SizedBox(height: 60),
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
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7F7F),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  onPressed: _loginCuentaRecuperar,
                  child: const Text('Recuperar Cuenta'),
                ),
              ),
              if (!_hasUsername) const SizedBox(height: 20),
              if (!_hasUsername)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA500),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: _loginRegistrar,
                    child: const Text('Registrarse'),
                  ),
                ),
              if (_hasUsername)
                TextButton(
                  onPressed: _deleteSavedUsername,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿No eres $_savedUsername? Haz clic aquí para cambiar de cuenta.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        height: 1,
                        color: const Color(0xFFCCCCCC),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
