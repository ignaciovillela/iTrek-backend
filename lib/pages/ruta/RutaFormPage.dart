import 'package:flutter/material.dart';

class RutaFormPage extends StatefulWidget {
  final int rutaId; // ID de la ruta
  final double distanceTraveled;
  final int secondsElapsed;
  final Function(Map<String, dynamic>) onSave;
  final VoidCallback onCancel;

  const RutaFormPage({
    required this.rutaId,
    required this.distanceTraveled,
    required this.secondsElapsed,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  @override
  _RutaFormPageState createState() => _RutaFormPageState();
}

class _RutaFormPageState extends State<RutaFormPage> {
  final _formKey = GlobalKey<FormState>();
  String _nombre = '';
  String _descripcion = '';
  String _dificultad = 'facil'; // Valor predeterminado para la dificultad

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar Detalles de la Ruta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre'),
                onSaved: (value) {
                  _nombre = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa un nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción'),
                onSaved: (value) {
                  _descripcion = value ?? '';
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa una descripción';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Dificultad'),
                value: _dificultad,
                items: const [
                  DropdownMenuItem(value: 'facil', child: Text('Fácil')),
                  DropdownMenuItem(value: 'moderada', child: Text('Moderada')),
                  DropdownMenuItem(value: 'dificil', child: Text('Difícil')),
                ],
                onChanged: (value) {
                  setState(() {
                    _dificultad = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _formKey.currentState?.save();
                        Map<String, dynamic> rutaData = {
                          "nombre": _nombre,
                          "descripcion": _descripcion,
                          "dificultad": _dificultad,
                        };

                        widget.onSave(rutaData); // Enviar los datos al backend
                      }
                    },
                    child: const Text('Guardar Ruta'),
                  ),
                  ElevatedButton(
                    onPressed: widget.onCancel,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Cancelar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
