import 'package:flutter/material.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  _RecuperarContrasenaScreenState createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Spacer(), // Espacio flexible para centrar el formulario verticalmente

              // Campo para ingresar el correo
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo Electrónico',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su correo electrónico';
                  } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Por favor, ingrese un correo válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20), // Espacio entre el campo y el botón

              // Botón para recuperar la contraseña
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Lógica para enviar el correo de recuperación
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Solicitud de recuperación enviada'),
                      ),
                    );
                  }
                },
                child: const Text('Recuperar Contraseña'),
              ),
              const SizedBox(height: 20), // Espacio entre los botones

              // Botón para cancelar
              TextButton(
                onPressed: () {
                  // Volver atrás o cancelar el proceso
                  Navigator.pop(context);
                },
                child: const Text('Cancelar'),
              ),

              const Spacer(), // Espacio al final para mantener la estructura
            ],
          ),
        ),
      ),
    );
  }
}
