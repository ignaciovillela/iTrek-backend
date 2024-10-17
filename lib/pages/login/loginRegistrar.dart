import 'package:flutter/material.dart';

import '../dashboard.dart'; // Importa la pantalla de inicio (HomeScreen)
import 'login.dart'; // Importa la pantalla de login

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _edadController = TextEditingController();

  String _sexo = 'Masculino'; // Valor inicial para el selector de sexo

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF50C9B5), // Color del AppBar
        title: Row(
          children: [
            Image.asset(
              'assets/images/logo.png', // Asegúrate de que el logo esté en la carpeta assets
              height: 30, // Tamaño pequeño del logo
            ),
            const SizedBox(width: 10), // Espacio entre el logo y el texto
            const Text('Registro de Usuario'),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              // Logo encima del campo de nombre
              Center(
                child: Image.asset(
                  'assets/images/perfil.png', // Asegúrate de que el logo esté en la carpeta assets
                  height: 200, // Tamaño más grande del logo
                ),
              ),
              const SizedBox(height: 30), // Espacio debajo del logo

              // Campo para el nombre
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para el correo
              TextFormField(
                controller: _correoController,
                decoration: InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su correo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para el número de contacto
              TextFormField(
                controller: _numeroController,
                decoration: InputDecoration(
                  labelText: 'Número de contacto',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su número de contacto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Selector para el sexo
              DropdownButtonFormField<String>(
                value: _sexo,
                decoration: InputDecoration(
                  labelText: 'Sexo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.wc),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: (value) {
                  setState(() {
                    _sexo = value ?? 'Masculino';
                  });
                },
              ),
              const SizedBox(height: 20),

              // Campo para la edad
              TextFormField(
                controller: _edadController,
                decoration: InputDecoration(
                  labelText: 'Edad',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su edad';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Botones de registrar y cancelar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Muestra un mensaje de éxito y navega a la pantalla Home
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Registro completado'),
                          ),
                        );
                        // Navegar a la pantalla de inicio (HomeScreen)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MenuScreen(),
                          ),
                        );
                      }
                    },
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
                    onPressed: () {
                      // Vuelve a la pantalla de login
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red, // Botón de cancelar en rojo
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

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
