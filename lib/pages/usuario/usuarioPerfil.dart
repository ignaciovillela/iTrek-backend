import 'dart:io';
import 'package:flutter/material.dart';
import 'package:itrek/db.dart';
import 'package:itrek/pages/usuario/login.dart';
import 'package:itrek/request.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart'; // Importa path_provider para obtener el directorio de almacenamiento

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

    // Si la imagen está en una ruta relativa, conviértela en absoluta
    if (imagenPerfil != null && imagenPerfil.isNotEmpty) {
      final Directory baseDir = await getApplicationDocumentsDirectory();
      final String rutaCompletaImagen = '${baseDir.path}$imagenPerfil'; // Ruta absoluta

      print("Ruta completa de la imagen construida: $rutaCompletaImagen");

      // Verifica si el archivo realmente existe en esa ruta
      final File file = File(rutaCompletaImagen);
      if (file.existsSync()) {
        print("Imagen encontrada en la ruta especificada.");
        _imagenPerfil = rutaCompletaImagen;
      } else {
        print("Imagen NO encontrada en la ruta especificada: $rutaCompletaImagen");

        // Imprime el contenido del directorio para verificar si el archivo realmente está allí
        final directoryContents = baseDir.listSync();
        print("Contenido del directorio base:");
        for (var entity in directoryContents) {
          print(entity.path); // Muestra los archivos y carpetas en el directorio base
        }
      }
    } else {
      print("No se ha especificado una imagen de perfil o está vacía.");
      _imagenPerfil = ''; // Usa una imagen predeterminada si no hay ruta de imagen
    }

    setState(() {
      _nombreController.text = firstName ?? '';
      _correoController.text = email ?? '';
      _biografiaController.text = biografia ?? '';
    });

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
                      ? FileImage(File(_imagenPerfil)) // Carga imagen local desde archivo
                      : const AssetImage('assets/images/profile.png') as ImageProvider,
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
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
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
