import 'package:flutter/material.dart';
import 'package:itrek/db/db.dart';
import 'package:itrek/pages/login/login.dart';

class PerfilUsuarioScreen extends StatefulWidget {
  const PerfilUsuarioScreen({super.key});

  @override
  _PerfilUsuarioScreenState createState() => _PerfilUsuarioScreenState();
}

class _PerfilUsuarioScreenState extends State<PerfilUsuarioScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos del formulario
  final TextEditingController _nombreController =
  TextEditingController(text: 'Juan Pérez');
  final TextEditingController _correoController =
  TextEditingController(text: 'juanperez@gmail.com');
  final TextEditingController _numeroController =
  TextEditingController(text: '555-1234');
  final TextEditingController _edadController =
  TextEditingController(text: '25');

  String _sexo = 'Masculino'; // Valor inicial para el selector de sexo
  bool _editMode = false; // Controla si los campos están en modo edición

  // Método para eliminar el token de la base de datos (cerrar sesión)
// Método para eliminar el token de la base de datos (cerrar sesión)
  Future<void> _cerrarSesion() async {
    try {
      await db.delete(db.token);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión cerrada exitosamente')),
      );

      // Redirigir al login después de cerrar sesión
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()), // Asegúrate de tener LoginScreen creada
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
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
              // Icono para personalizar el perfil (simulando una imagen de perfil)
              GestureDetector(
                onTap: () {
                  if (_editMode) {
                    // Solo permitir cambiar la imagen si está en modo edición
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cambiar imagen de perfil'),
                      ),
                    );
                  }
                },
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blueAccent,
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Colors.white,
                  ),
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

              // Campo para el número de contacto
              TextFormField(
                controller: _numeroController,
                decoration: const InputDecoration(
                  labelText: 'Número de contacto',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                enabled: _editMode, // Deshabilitado si no está en modo edición
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
                decoration: const InputDecoration(
                  labelText: 'Sexo',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'Masculino', child: Text('Masculino')),
                  DropdownMenuItem(value: 'Femenino', child: Text('Femenino')),
                  DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                ],
                onChanged: _editMode
                    ? (value) {
                  setState(() {
                    _sexo = value ?? 'Masculino';
                  });
                }
                    : null, // Deshabilitado si no está en modo edición
              ),
              const SizedBox(height: 20),

              // Campo para la edad
              TextFormField(
                controller: _edadController,
                decoration: const InputDecoration(
                  labelText: 'Edad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                enabled: _editMode, // Deshabilitado si no está en modo edición
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese su edad';
                  }
                  return null;
                },
              ),
              const SizedBox(
                  height: 40), // Espacio mayor antes del botón de editar

              // Botón para editar el perfil
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF50C9B5), // Color verde pastel del botón
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
                    minimumSize:
                    const Size(double.infinity, 50), // Botón grande
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
                        _editMode =
                        false; // Desactivar modo edición después de guardar
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
