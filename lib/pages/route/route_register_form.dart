import 'package:flutter/material.dart';
import 'package:itrek/helpers/widgets.dart';

class RutaFormPage extends StatefulWidget {
  final int rutaId;
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
  String _dificultad = 'facil';
  bool _esPublica = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Detalles de la Ruta'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador de progreso
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.teal.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem(
                      icon: Icons.directions_walk,
                      label: 'Distancia',
                      value: _formatDistance(widget.distanceTraveled),
                    ),
                    _buildInfoItem(
                      icon: Icons.timer,
                      label: 'Tiempo',
                      value: _formatTime(widget.secondsElapsed),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Formulario dentro de una tarjeta
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detalles de la Ruta',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                      const SizedBox(height: 20),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Descripción',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
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
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Dificultad',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        value: _dificultad,
                        items: const [
                          DropdownMenuItem(
                              value: 'facil', child: Text('Fácil')),
                          DropdownMenuItem(
                              value: 'moderada', child: Text('Moderada')),
                          DropdownMenuItem(
                              value: 'dificil', child: Text('Difícil')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _dificultad = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        title: const Text('¿Hacer esta ruta pública?'),
                        value: _esPublica,
                        onChanged: (bool value) {
                          setState(() {
                            _esPublica = value;
                          });
                        },
                        activeColor: Colors.teal.shade700,
                        inactiveThumbColor: Colors.grey,
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _formKey.currentState?.save();
                                Map<String, dynamic> rutaData = {
                                  "nombre": _nombre,
                                  "descripcion": _descripcion,
                                  "dificultad": _dificultad,
                                  "publica": _esPublica
                                };
                                widget.onSave(rutaData);
                              }
                            },
                            icon: const Icon(Icons.save, color: Colors.white),
                            label: const Text('Guardar', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: widget.onCancel,
                            icon: const Icon(Icons.cancel, color: Colors.white),
                            label: const Text('Cancelar', style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(
      {required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.teal.shade700, size: 30),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  String _formatTime(int seconds) {
    if (seconds < 60) {
      // Menos de 1 minuto: Mostrar solo segundos
      return '${seconds}s';
    } else if (seconds < 3600) {
      // Menos de 1 hora: Mostrar minutos y segundos
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      // Más de 1 hora: Mostrar horas, minutos y segundos
      int hours = seconds ~/ 3600;
      int minutes = (seconds % 3600) ~/ 60;
      int remainingSeconds = seconds % 60;
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  String _formatDistance(double distanceInMeters) {
    return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
  }


}

