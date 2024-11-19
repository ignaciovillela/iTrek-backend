import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:itrek/config.dart';
import 'package:itrek/db.dart';
import 'package:itrek/pages/auth/login.dart';
import 'package:itrek/request.dart';
import 'package:itrek/helpers/widgets.dart';

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

  Future<void> _loadUserData() async {
    final userData = await db.values.getUserData();
    final imagenPerfil = userData[db.values.imagen_perfil];
    setState(() {
      _userNameController.text = userData[db.values.username] ?? "";
      _nombreController.text = userData[db.values.first_name] ?? "";
      _apellidoController.text = userData[db.values.last_name] ?? "";
      _biografiaController.text = userData[db.values.biografia] ?? "";
      _imagenPerfil = (imagenPerfil != null && imagenPerfil.isNotEmpty)
          ? '$BASE_URL$imagenPerfil'
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

  Future<void> _cerrarSesion() async {
    await makeRequest(
      method: POST,
      url: LOGOUT,
      useToken: true,
      onDefault: (response) async {
        await db.values.delete(db.values.token);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false, // Evita que el contenido cambie su tamaño automáticamente
      appBar: CustomAppBar(title: 'Perfil de Usuario'),
      body: Stack(
        children: [
          // Contenido principal con scroll
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Espacio para el footer
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Imagen de perfil
                  Center(
                    child: buildProfileImage(
                      imageUrl: _imagenPerfil,
                      imageFile: _imageFile,
                      onEdit: _pickImage,
                      editMode: _editMode,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Nombre de usuario
                  Text(
                    _userNameController.text,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campos de texto
                  ProfileTextField(
                    controller: _nombreController,
                    label: 'Nombre',
                    enabled: _editMode,
                  ),
                  const SizedBox(height: 20),
                  ProfileTextField(
                    controller: _apellidoController,
                    label: 'Apellido',
                    enabled: _editMode,
                  ),
                  const SizedBox(height: 20),
                  ProfileTextField(
                    controller: _biografiaController,
                    label: 'Biografía',
                    enabled: _editMode,
                  ),
                ],
              ),
            ),
          ),

          // Footer fijo con botones flotantes
          FixedFooter(
            children: [
              CircleIconButton(
                icon: _editMode ? Icons.save : Icons.edit,
                color: _editMode ? Colors.green : colorScheme.primary,
                onPressed: () {
                  setState(() {
                    _editMode = !_editMode;
                  });
                  if (!_editMode) _loadUserData();
                },
              ),
              CircleIconButton(
                icon: Icons.logout,
                color: colorScheme.error,
                onPressed: _cerrarSesion,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
