import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itrek/config.dart';
import 'package:itrek/db.dart';
import 'package:itrek/pages/usuario/login.dart';
import 'package:itrek/request.dart';
import 'package:http/http.dart' as http;
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
  final TextEditingController _apellidoController = TextEditingController();

  String _imagenPerfil = '';
  bool _editMode = false;
  final ImagePicker _picker = ImagePicker();
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      _imagenPerfil = imagenPerfil != null && imagenPerfil.isNotEmpty
          ? (imagenPerfil.startsWith('http') ? imagenPerfil : '$BASE_URL$imagenPerfil')
          : 'assets/images/profile.png';
    });

    print("Cargado: $_imagenPerfil, $firstName, $email, $biografia");
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile() async {
    // Obtiene el token de la base de datos
    final token = await db.values.get('token');

    // Verifica si el token es nulo o está vacío
    if (token == null || token.toString().trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Token de autenticación no encontrado.")),
      );
      return;
    }

    // Configura los encabezados con el token
    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Token ${token.toString().trim()}"
    };

    print("Encabezados de la solicitud: $headers");

    // Define la URL para la solicitud
    final url = Uri.parse('$BASE_URL/$UPDATE_USER');

    // Verifica que los campos no estén vacíos y asigna valores predeterminados si es necesario
    final lastName = _apellidoController.text.trim().isEmpty ? "Apellido" : _apellidoController.text.trim();
    final password = "Sofia1234Trinidad"; // Usa una contraseña predeterminada (modifícalo según sea necesario)

    // Define el cuerpo de la solicitud sin `imagen_perfil`
    final body = jsonEncode({
      "username": _nombreController.text.trim(),
      "password": password,
      "email": _correoController.text.trim(),
      "first_name": _nombreController.text.trim(),
      "last_name": lastName,
      "biografia": _biografiaController.text.trim()
    });

    try {
      // Realiza la solicitud HTTP PUT
      final response = await http.put(url, headers: headers, body: body);

      // Comprueba el estado de la respuesta
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Actualiza los valores en la base de datos local
        await db.values.create('usuario_first_name', responseData['first_name']);
        await db.values.create('usuario_email', responseData['email']);
        await db.values.create('usuario_biografia', responseData['biografia']);
        await db.values.create('usuario_last_name', responseData['last_name']);
        await db.values.create('username', responseData['username']);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );

        setState(() {
          _editMode = false;
        });

        // Recarga los datos actualizados del usuario
        _loadUserData();
      } else {
        print("Error: ${response.statusCode}, Body: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al actualizar el perfil: ${response.body}")),
        );
      }
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : NetworkImage(_imagenPerfil) as ImageProvider,
                    backgroundColor: Colors.grey[200],
                  ),
                  if (_editMode)
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: _pickImage,
                    ),
                ],
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
                  if (!_editMode) _loadUserData();
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
                      await _updateProfile();
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
