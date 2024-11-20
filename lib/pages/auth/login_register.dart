import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/widgets.dart';
import 'login.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _biografiaController = TextEditingController();

  bool _isLoading = false;

  Map<String, String?> _fieldErrors = {};

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _biografiaController.dispose();
    super.dispose();
  }

  Future<void> _registrarUsuario() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String email = _emailController.text.trim();
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String biografia = _biografiaController.text.trim();

    Map<String, String> body = {
      'username': username,
      'password': password,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'biografia': biografia,
    };

    await makeRequest(
      method: POST,
      url: USER_CREATE,
      body: body,
      useToken: false,
      onOk: (response) async {
        final jsonData = jsonDecode(response.body);
        final mensaje = jsonData['message'] ?? 'Registro exitoso';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      },
      onError: (response) {
        setState(() {
          _fieldErrors.clear();

          final jsonData = jsonDecode(response.body);
          jsonData.forEach((key, value) {
            _fieldErrors[key] = value is List ? value.join(', ') : value.toString();
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Por favor, corrija los errores'),
            ),
          );
        });
      },
      onConnectionError: (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );

    setState(() {
      _isLoading = false;
    });
  }

  // Function to cancel and return to login
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(title: 'Registro de Usuario'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Username field
              CustomTextField(
                controller: _usernameController,
                label: 'Nombre de Usuario',
                icon: Icons.person,
                errorText: _fieldErrors['username'],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese un nombre de usuario';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Password field
              CustomTextField(
                controller: _passwordController,
                label: 'Contraseña',
                icon: Icons.lock,
                obscureText: true,
                errorText: _fieldErrors['password'],
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
              // Confirm Password field
              CustomTextField(
                controller: _confirmPasswordController,
                label: 'Confirmar Contraseña',
                icon: Icons.lock_outline,
                obscureText: true,
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
              // Email field
              CustomTextField(
                controller: _emailController,
                label: 'Correo Electrónico',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                errorText: _fieldErrors['email'],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su correo electrónico';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Ingrese un correo electrónico válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // First Name field
              CustomTextField(
                controller: _firstNameController,
                label: 'Nombre',
                icon: Icons.account_circle,
                errorText: _fieldErrors['first_name'],
              ),
              const SizedBox(height: 20),
              // Last Name field
              CustomTextField(
                controller: _lastNameController,
                label: 'Apellido',
                icon: Icons.account_circle_outlined,
                errorText: _fieldErrors['last_name'],
              ),
              const SizedBox(height: 20),
              // Biography field
              CustomTextField(
                controller: _biografiaController,
                label: 'Biografía',
                icon: Icons.description,
                maxLines: 3,
                errorText: _fieldErrors['biografia'],
              ),
              const SizedBox(height: 30),
              // Register and Cancel buttons
              _isLoading
                  ? const CircularProgressIndicator()
                  : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: _registrarUsuario,
                      icon: const Icon(Icons.app_registration, color: Colors.white),
                      label: const Text('Registrar', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        textStyle: const TextStyle(fontSize: 18),
                        side: BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                      ),
                      onPressed: _cancelarRegistro,
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text('Cancelar', style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
