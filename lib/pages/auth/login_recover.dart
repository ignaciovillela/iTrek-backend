import 'package:flutter/material.dart';
import 'package:itrek/helpers/img.dart';

class RecuperarContrasenaScreen extends StatefulWidget {
  const RecuperarContrasenaScreen({super.key});

  @override
  _RecuperarContrasenaScreenState createState() =>
      _RecuperarContrasenaScreenState();
}

class _RecuperarContrasenaScreenState extends State<RecuperarContrasenaScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _correoController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF50C9B5), // Color de fondo del AppBar
        title: Row(
          children: [
            logoWhite,
            const SizedBox(width: 10), // Espacio entre el logo y el texto
            const Text(
              'Recuperar Cuenta',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView( // Funcion de Scroll
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment:
              MainAxisAlignment.center, // Centrar contenido verticalmente
              children: [
                const SizedBox(height: 40), // Espacio debajo del título

                // Imagen logo debajo del título
                logoWhite,
                const SizedBox(
                    height: 160), // Espacio entre la imagen y el campo de texto

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

                // Botón para recuperar la cuenta
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50C9B5),
                    minimumSize: const Size(double.infinity, 50), // Botón ancho
                  ),
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
                  child: const Text('Recuperar Cuenta'),
                ),
                const SizedBox(height: 20), // Espacio entre los botones

                // Botón para cancelar
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC95052),
                    minimumSize: const Size(double.infinity, 50), // Botón ancho
                  ),
                  onPressed: () {
                    // Regresar a la pantalla de inicio de sesión (LoginScreen)
                    Navigator.pop(context); // Volver atrás
                  },
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.white), // Texto en blanco
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
