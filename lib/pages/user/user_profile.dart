import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:itrek/helpers/config.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/helpers/widgets.dart';
import 'package:itrek/pages/auth/login.dart';
import 'package:permission_handler/permission_handler.dart';

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
    _askPermissions();
    _loadUserData();
  }

  Future<void> _askPermissions() async {
    await Permission.camera.request();
    await Permission.storage.request();
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

  Future<void> _guardarDatos() async {
    final updatedData = {
      "username": _userNameController.text.isNotEmpty ? _userNameController.text : "Sin Nombre",
      "first_name": _nombreController.text.isNotEmpty ? _nombreController.text : "Sin Nombre",
      "last_name": _apellidoController.text.isNotEmpty ? _apellidoController.text : "Sin Apellido",
      "biografia": _biografiaController.text.isNotEmpty ? _biografiaController.text : "Sin Biografía",
    };

    if (_imageFile != null) {
      Uint8List originalImageBytes = await _imageFile!.readAsBytes();
      Uint8List resizedImageBytes = await _resizeImage(originalImageBytes, 800);
      updatedData["imagen_perfil"] = base64Encode(resizedImageBytes);
      print("Imagen codificada en Base64: ${updatedData["imagen_perfil"]}");
    }

    await makeRequest(
      method: PUT,
      url: USER_UPDATE,
      body: updatedData,
      onOk: (response) async {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        await db.values.setUserData({
          "username": responseData["username"] ?? updatedData["username"],
          "first_name": responseData["first_name"] ?? updatedData["first_name"],
          "last_name": responseData["last_name"] ?? updatedData["last_name"],
          "biografia": responseData["biografia"] ?? updatedData["biografia"],
          "imagen_perfil": responseData["imagen_perfil"] ?? updatedData["imagen_perfil"],
        });

        setState(() {
          _userNameController.text = responseData["username"] ?? updatedData["username"];
          _nombreController.text = responseData["first_name"] ?? updatedData["first_name"];
          _apellidoController.text = responseData["last_name"] ?? updatedData["last_name"];
          _biografiaController.text = responseData["biografia"] ?? updatedData["biografia"];

          final imagenPerfil = responseData["imagen_perfil"];
          _imagenPerfil = (imagenPerfil != null && imagenPerfil.isNotEmpty)
              ? '$BASE_URL$imagenPerfil'
              : 'assets/images/profile.png';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados exitosamente.')),
        );
      },
      onError: (response) {
        print('Error al guardar datos en el backend: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar datos: ${response.body}')),
        );
      },
      onConnectionError: (errorMessage) {
        print('Error de conexión: $errorMessage');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de conexión: $errorMessage')),
        );
      },
    );
  }

  Future<Uint8List> _resizeImage(Uint8List originalImageBytes, int maxDimension) async {
    final originalImage = img.decodeImage(originalImageBytes);
    if (originalImage == null) {
      throw Exception("No se pudo decodificar la imagen.");
    }

    int width = originalImage.width;
    int height = originalImage.height;

    // Calcular el factor de escala para mantener el aspect ratio
    if (width > height) {
      if (width > maxDimension) {
        height = (height * maxDimension) ~/ width;
        width = maxDimension;
      }
    } else {
      if (height > maxDimension) {
        width = (width * maxDimension) ~/ height;
        height = maxDimension;
      }
    }

    final resizedImage = img.copyResize(
      originalImage,
      width: width,
      height: height,
    );

    return Uint8List.fromList(img.encodeJpg(resizedImage));
  }

  Future<ImageSource?> _showImageSourceDialog() async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar fuente de imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImageSource? source = await _showImageSourceDialog();
    if (source == null) return; // Usuario canceló

    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      if (await file.exists() && await file.length() > 0) {
        final originalImageBytes = await file.readAsBytes();

        // Decodificar la imagen para verificar si es válida
        final originalImage = img.decodeImage(originalImageBytes);
        if (originalImage == null) {
          print("No se pudo decodificar la imagen. El archivo puede estar corrupto.");
          return;
        }

        // Redimensionar la imagen manteniendo el aspect ratio
        final resizedImageBytes = await _resizeImage(originalImageBytes, 800);

        setState(() {
          _imageFile = file; // Almacena el archivo original
          // Puedes almacenar los bytes redimensionados si lo necesitas
          //_resizedImageBytes = resizedImageBytes;
        });
      } else {
        print("El archivo está vacío o no existe.");
      }
    } else {
      print("No se seleccionó ninguna imagen.");
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
                  if (!_editMode) _guardarDatos();
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
