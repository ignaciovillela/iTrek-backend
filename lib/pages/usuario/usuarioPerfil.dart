import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Importa image_picker
import 'package:itrek/config.dart';
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
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _correoController = TextEditingController();
  final TextEditingController _biografiaController = TextEditingController();
  String _imagenPerfil = '';
  bool _editMode = false;
  final ImagePicker _picker = ImagePicker(); // Crea una instancia de ImagePicker
  File? _imageFile; // Archivo temporal para la imagen seleccionada

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final firstName = await db.values.get('usuario_first_name') as String?;
    final email = await db.values.get('usuario_email') as String?;
    final biografia = await db.values.get('usuario_biografia') as String?;
    final imagenPerfil = await db.values.get('usuario_imagen_perfil') as String?;

    setState(() {
      _nombreController.text = firstName ?? '';
      _correoController.text = email ?? '';
      _biografiaController.text = biografia ?? '';

      if (imagenPerfil != null && imagenPerfil.isNotEmpty) {
        if (!imagenPerfil.startsWith('http')) {
          _imagenPerfil = '${BASE_URL}${imagenPerfil}';
        } else {
          _imagenPerfil = imagenPerfil;
        }
      } else {
        _imagenPerfil = 'assets/images/profile.png';
      }
    });

    print("Cargado: $_imagenPerfil, $firstName, $email, $biografia");
  }

  // Método para seleccionar una nueva imagen de perfil
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Método para subir la imagen al servidor
  Future<void> _uploadImage() async {
    if (_imageFile != null) {
      // Aquí enviarías _imageFile al servidor y obtendrías una URL de respuesta
      // Ejemplo ficticio:
      final newImageUrl = '/media/imagenes_perfil/nueva_imagen.png';

      setState(() {
        _imagenPerfil = '${BASE_URL}$newImageUrl';
      });

      await db.values.create('usuario_imagen_perfil', newImageUrl);
    }
  }

  Future<void> _cerrarSesion() async {
    await makeRequest(
      method: POST,
      url: LOGOUT,
      useToken: true,
      onOk: (response) async {
        await db.values.delete(db.values.token);
        final message = jsonDecode(response.body)['message'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

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
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF50C9B5),
        title: const Text('Perfil de Usuario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  if (_editMode) await _pickImage();
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!) // Imagen seleccionada por el usuario
                      : NetworkImage(_imagenPerfil) as ImageProvider, // Carga imagen desde URL o predeterminada
                  backgroundColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                enabled: _editMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: _editMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su correo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _biografiaController,
                decoration: const InputDecoration(
                  labelText: 'Biografía',
                  border: OutlineInputBorder(),
                ),
                enabled: _editMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su biografía';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF50C9B5),
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: () {
                  setState(() {
                    _editMode = !_editMode;
                  });
                },
                icon: const Icon(Icons.edit),
                label: Text(_editMode ? 'Cancelar Edición' : 'Editar Perfil'),
              ),
              const SizedBox(height: 20),
              if (_editMode)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF50C9B5),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await _uploadImage(); // Sube la nueva imagen al servidor
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cambios guardados exitosamente'),
                        ),
                      );
                      setState(() {
                        _editMode = false;
                      });
                    }
                  },
                  child: const Text('Guardar Cambios'),
                ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                ),
                onPressed: _cerrarSesion,
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
