import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/auth/login_recover.dart';
import 'package:itrek/pages/auth/login_register.dart';
import 'package:itrek/pages/dashboard.dart';

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

  bool _hasUsername = false;
  String? _savedUsername;

  bool _isLoading = false;

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

    _checkForSavedUsername();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkForSavedUsername() async {
    final username = await db.values.get(db.values.username);
    if (username != null) {
      setState(() {
        _hasUsername = true;
        _savedUsername = username.toString();
      });
    }
  }

  Future<void> _deleteSavedUsername() async {
    await db.values.delete(db.values.username);
    setState(() {
      _hasUsername = false;
      _savedUsername = null;
    });
  }

  Future<void> _login() async {
    final String username = _hasUsername ? _savedUsername! : _usernameController.text.trim();
    final String password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre de usuario y la contraseña no pueden estar vacíos')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

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

    setState(() {
      _isLoading = false;
    });
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RegistroScreen()),
    );
  }

  void _navigateToRecoverPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecuperarContrasenaScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: 'iTrek', withLogo: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
              const SizedBox(height: 40),
              if (!_hasUsername)
                CustomTextField(
                  controller: _usernameController,
                  label: 'Nombre de Usuario',
                  icon: Icons.person,
                ),
              if (_hasUsername)
                Column(
                  children: [
                    Text(
                      'Hola, $_savedUsername! Nos alegra verte de nuevo.\nPor favor, ingresa tu contraseña para continuar.',
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                  ],
                )
              else
                SizedBox(height: 10),
              CustomTextField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _login,
                    icon: const Icon(Icons.login, color: Colors.white),
                    label: const Text('Ingresar', style: TextStyle(color: Colors.white)),
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _navigateToRecoverPassword,
                child: const Text('¿Olvidaste tu contraseña?'),
              ),
              const SizedBox(height: 20),
              if (!_hasUsername)
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.person_add, color: colorScheme.primary),
                    label: Text(
                      'Registrarse',
                      style: TextStyle(color: colorScheme.primary),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      textStyle: const TextStyle(fontSize: 18),
                      side: BorderSide(color: colorScheme.primary, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _navigateToRegister,
                  ),
                ),
              if (_hasUsername)
                TextButton(
                  onPressed: _deleteSavedUsername,
                  child: Text(
                    '¿No eres $_savedUsername? Haz clic aquí para cambiar de cuenta.',
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
