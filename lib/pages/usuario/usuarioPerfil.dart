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
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _nombreController = TextEditingController();
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
    final userName = await db.values.get('username') as String?;
    final firstName = await db.values.get('first_name') as String?;
    final lastName = await db.values.get('last_name') as String?;
    final biografia = await db.values.get('biografia') as String?;
    final imagenPerfil = await db.values.get('imagen_perfil') as String?;
    setState(() {
      _userNameController.text = userName ?? '';
      _nombreController.text = firstName ?? '';
      _apellidoController.text = lastName ?? '';
      _biografiaController.text = biografia ?? '';
      _imagenPerfil = imagenPerfil != null && imagenPerfil.isNotEmpty
          ? (imagenPerfil.startsWith('http') ? imagenPerfil : '$BASE_URL$imagenPerfil')
          : 'assets/images/profile.png';
    });
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

    final url = Uri.parse('$BASE_URL/$USER_UPDATE');

    // Convierte la imagen a base64 si existe
    String? base64Image;
    if (_imageFile != null) {
      List<int> imageBytes = await _imageFile!.readAsBytes();
      base64Image = base64Encode(imageBytes);
    }

    // Define el cuerpo de la solicitud, incluyendo la imagen en formato base64
    final body = jsonEncode({
      "first_name": _nombreController.text.trim(),
      "last_name": _apellidoController.text.trim(),
      "biografia": _biografiaController.text.trim(),
      if (base64Image != null) "imagen_perfil": base64Image,
    });
    try {
      // Realiza la solicitud HTTP PUT
      final response = await http.put(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Usa el método `createLoginData` para guardar los datos en la base de datos
        await db.values.createLoginData({
          'first_name': responseData['first_name'],
          'last_name': responseData['last_name'],
          'biografia': responseData['biografia'],
          'imagen_perfil': responseData['imagen_perfil'],
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );

        setState(() {
          _editMode = false;
        });

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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Color(0xFFA5D6A7),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: _pickImage,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _userNameController.text, // Nombre de usuario
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                controller: _apellidoController,
                decoration: const InputDecoration(
                  labelText: 'Apellido',
                  border: OutlineInputBorder(),
                ),
                enabled: _editMode,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su apellido';
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
