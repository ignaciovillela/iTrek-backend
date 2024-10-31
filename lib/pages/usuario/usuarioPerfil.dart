import 'package:flutter/material.dart';
import 'package:itrek/db.dart';
import 'package:itrek/pages/usuario/login.dart';
import 'package:itrek/request.dart';
import 'dart:convert';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  _PerfilUsuarioScreenState createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _biografiaController = TextEditingController();
  String _imagenPerfil = ''; // Para almacenar la URL o el path de la imagen de perfil
  bool _editMode = false; // Controla si los campos están en modo edición

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Cargar datos del usuario desde la base de datos
  }

  // Cargar datos del usuario desde la base de datos
  Future<void> _loadUserData() async {
    final username = await db.values.get('usuario_username') as String?;
    final email = await db.values.get('usuario_email') as String?;
    final firstName = await db.values.get('usuario_first_name') as String?;
    final lastName = await db.values.get('usuario_last_name') as String?;
    final biografia = await db.values.get('usuario_biografia') as String?;
    final imagenPerfil = await db.values.get('usuario_imagen_perfil') as String?;

    setState(() {
      _nombreController.text = firstName ?? '';
      _correoController.text = email ?? '';
      _biografiaController.text = biografia ?? '';
      _imagenPerfil = imagenPerfil ?? '';
    });

    // Debug: Imprimir datos cargados
    print("Cargado: $_imagenPerfil, $firstName, $email, $biografia");
  }

  Future<void> _cerrarSesion() async {
    await makeRequest(
      method: POST,
      url: LOGOUT,
      useToken: true,
      onOk: (response) async {
        await db.values.delete(db.values.token);

        final message = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
      onError: (response) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al cerrar sesión')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDFF0D8), // Fondo verde pastel
      appBar: AppBar(
        backgroundColor: const Color(0xFF50C9B5),
        title: const Text('Perfil de Usuario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Regresa a la pantalla anterior
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Mostrar imagen de perfil
              GestureDetector(
                onTap: () {
                  if (_editMode) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cambiar imagen de perfil'),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imagenPerfil.isNotEmpty
                      ? NetworkImage(_imagenPerfil) // Cambia a NetworkImage si la imagen es de la red
                      : const AssetImage('assets/default_profile.png') as ImageProvider,
                  backgroundColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),

              // Campo para el nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                enabled: _editMode, // Deshabilitado si no está en modo edición
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
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: _editMode, // Deshabilitado si no está en modo edición
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su correo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Campo para biografía
              TextFormField(
                controller: _biografiaController,
                decoration: const InputDecoration(
                  labelText: 'Biografía',
                  border: OutlineInputBorder(),
                ),
                enabled: _editMode, // Deshabilitado si no está en modo edición
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su biografía';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40), // Espacio mayor antes del botón de editar

              // Botón para editar el perfil
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF50C9B5), // Color verde pastel del botón
                  minimumSize: const Size(double.infinity, 50), // Botón grande
                ),
                onPressed: () {
                  setState(() {
                    _editMode = !_editMode; // Habilitar o deshabilitar edición
                  });
                },
                icon: const Icon(Icons.edit),
                label: Text(_editMode ? 'Cancelar Edición' : 'Editar Perfil'),
              ),

              const SizedBox(height: 20),

              // Botón para guardar los cambios
              if (_editMode)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50C9B5),
                    minimumSize: const Size(double.infinity, 50), // Botón grande
                  ),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      // Lógica para guardar los cambios
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cambios guardados exitosamente'),
                        ),
                      );
                      setState(() {
                        _editMode = false; // Desactivar modo edición después de guardar
                      });
                    }
                  },
                  child: const Text('Guardar Cambios'),
                ),

              const SizedBox(height: 20),

              // Botón para cerrar sesión
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50), // Botón grande
                ),
                onPressed: _cerrarSesion, // Llama al método para cerrar sesión
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
