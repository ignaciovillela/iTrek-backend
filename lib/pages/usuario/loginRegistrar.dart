import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:itrek/request.dart'; // Importa 'makeRequest'
import 'login.dart';

const String POST_USER = 'api/users/create/'; // Define la constante para el endpoint

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController(); // Nuevo controlador
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _biografiaController = TextEditingController();

  bool _isLoading = false; // Para mostrar un indicador de carga

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose(); // Asegurarse de eliminar el controlador
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _biografiaController.dispose();
    super.dispose();
  }

  // Función para registrar al usuario
  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true; // Mostrar indicador de carga
    });

    // Recoger los datos del formulario
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String email = _emailController.text.trim();
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String biografia = _biografiaController.text.trim();

    // Crear el cuerpo de la solicitud
    Map<String, String> body = {
      'username': username,
      'password': password,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'biografia': biografia,
    };

    // Realizar la solicitud POST usando makeRequest
    await makeRequest(
      method: POST,
      url: USER_CREATE,
      body: body,
      useToken: false,
      onOk: (response) async {
        final jsonData = jsonDecode(response.body);
        final mensaje = jsonData['message'] ?? 'Registro exitoso';

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
          ),
        );

        // Navegar a la pantalla de inicio de sesión
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Error en el registro: ${response.statusCode} - ${response.reasonPhrase}'),
          ),
        );
      },
      onConnectionError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );

    setState(() {
      _isLoading = false; // Ocultar indicador de carga
    });
  }

  // Función para cancelar y volver al login
  void _cancelarRegistro() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        backgroundColor: const Color(0xFF50C9B5), // Color del AppBar
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            // Usamos ListView para permitir scroll si es necesario
            children: [
              const SizedBox(height: 20),

              // Campo para el username
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de Usuario',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un nombre de usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para la contraseña
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                ),
                obscureText: true, // Oculta el texto para contraseñas
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese una contraseña';
                  }
                  if (value.length < 6) {
                    return 'La contraseña debe tener al menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para la confirmación de contraseña
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirmar Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                ),
                obscureText: true, // Oculta el texto para contraseñas
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme su contraseña';
                  }
                  if (value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para el email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su correo electrónico';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Ingrese un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para el primer nombre
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para el apellido
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_circle_outlined),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su apellido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para la biografía
              TextFormField(
                controller: _biografiaController,
                decoration: InputDecoration(
                  labelText: 'Biografía',
                  border: OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) {
                  // La biografía puede ser opcional
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Botones de registrar y cancelar
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _registrarUsuario, // Llama a la función de registro
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                          0xFF50C9B5), // Botón de registrar color verde
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text('Registrar'),
                  ),
                  ElevatedButton(
                    onPressed: _cancelarRegistro, // Llama a la función de cancelar
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      Colors.red, // Botón de cancelar en rojo
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
