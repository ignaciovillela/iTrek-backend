import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:itrek/helpers/request.dart';

class ActivtyScreen extends StatefulWidget {
  const ActivtyScreen({super.key});

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivtyScreen> {
  Map<String, dynamic>? userStats;
  bool _isLoading = true;
  String filtroSeleccionado = 'todas'; // Filtros disponibles: todas, creadas, compartidas, comentarios, puntajes

  @override
  void initState() {
    super.initState();
    _fetchUserActivity();
  }

  Future<void> _fetchUserActivity() async {
    await makeRequest(
      method: GET,
      url: USER_ACTIVITY,
      onOk: (response) {
        final responseData = jsonDecode(response.body);
        setState(() {
          userStats = responseData;
          _isLoading = false;
        });
      },
      onError: (response) {
        setState(() {
          userStats = null;
          _isLoading = false;
        });
      },
      onConnectionError: (errorMessage) {
        setState(() {
          userStats = null;
          _isLoading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro de Actividad')),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (userStats == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registro de Actividad')),
        body: const Center(
          child: Text(
            'No se pudieron cargar los datos.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Actividad'),
      ),
      body: Column(
        children: [
          _buildFiltrosPrincipales(),
          Expanded(child: _buildFilteredContent()),
        ],
      ),
    );
  }

  Widget _buildFiltrosPrincipales() {
    const filtros = [
      {'label': 'Todas', 'value': 'todas'},
      {'label': 'Mis Rutas Creadas', 'value': 'creadas'},
      {'label': 'Rutas Compartidas Conmigo', 'value': 'compartidas'},
      {'label': 'Mis Rutas Compartidas', 'value': 'compartidas_por_mi'},
      {'label': 'Mis Comentarios', 'value': 'comentarios'},
      {'label': 'Mis Calificaciones', 'value': 'puntajes'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filtros.map((filtro) {
          final isSelected = filtroSeleccionado == filtro['value'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(
                filtro['label']!,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  filtroSeleccionado = filtro['value']!;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilteredContent() {
    switch (filtroSeleccionado) {
      case 'creadas':
      case 'compartidas':
      case 'compartidas_por_mi':
      case 'comentarios':
      case 'puntajes':
        return _buildFilteredSection(filtroSeleccionado);
      default: // Caso 'todas'
        return ListView(
          children: [
            _buildFilteredSection('creadas'),
            _buildFilteredSection('compartidas'),
            _buildFilteredSection('compartidas_por_mi'),
            _buildFilteredSection('comentarios'),
            _buildFilteredSection('puntajes'),
          ],
        );
    }
  }

  Widget _buildFilteredSection(String filtro) {
    switch (filtro) {
      case 'creadas':
        return _buildSection(
          title: 'Mis Rutas Creadas',
          items: userStats!['rutas_creadas'],
          itemBuilder: (item) => _buildRutaCard(item),
        );
      case 'compartidas':
        return _buildSection(
          title: 'Rutas Compartidas Conmigo',
          items: userStats!['rutas_compartidas'],
          itemBuilder: (item) => _buildRutaCard(item, isShared: true),
        );
      case 'compartidas_por_mi':
        final usuariosCompartidos = _getUsuariosCompartidos(userStats!['rutas_creadas']);
        return _buildSection(
          title: 'Mis Rutas Compartidas',
          items: usuariosCompartidos,
          itemBuilder: (item) => _buildRutaCard(
            item['ruta'],
            isUserShare: true,
            sharedUser: item['ruta']['usuario']['username'],
          ),
        );
      case 'comentarios':
        return _buildSection(
          title: 'Mis Comentarios',
          items: userStats!['comentarios'],
          itemBuilder: (item) => _buildRutaCard(
            item['ruta'],
            isComment: true,
            commentText: item['descripcion'],
          ),
        );
      case 'puntajes':
        return _buildSection(
          title: 'Mis Calificaciones',
          items: userStats!['puntajes'],
          itemBuilder: (item) => _buildRutaCard(
            item['ruta'],
            isScore: true,
            scoreValue: item['puntaje'],
          ),
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildSection({
    required String title,
    required List<dynamic> items,
    required Widget Function(dynamic) itemBuilder,
  }) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'No hay $title disponibles.',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ...items.map(itemBuilder).toList(),
        ],
      ),
    );
  }

  Widget _buildRutaCard(
      dynamic ruta, {
        bool isShared = false,
        bool isComment = false,
        bool isScore = false,
        bool isUserShare = false,
        String? commentText,
        double? scoreValue,
        String? sharedUser,
      }) {
    final double puntaje = (ruta['puntaje'] as num?)?.toDouble() ?? 0.0;
    final String puntajeDisplay = puntaje > 0 ? puntaje.toStringAsFixed(1) : '---';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12.0),
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isShared ? Icons.share
                  : isComment ? Icons.comment
                  : isScore ? Icons.star
                  : isUserShare ? Icons.people
                  : Icons.map,
              color: isShared ? Colors.purple
                  : isComment ? Colors.blue
                  : isScore ? Colors.amber
                  : isUserShare ? Colors.teal
                  : Colors.green,
              size: 30,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(puntajeDisplay, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(width: 2),
                const Icon(Icons.star, size: 18, color: Colors.amber),
              ],
            ),
          ],
        ),
        title: Text(
          ruta['nombre'],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ruta['descripcion'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Dificultad: ${ruta['dificultad'] ?? 'Desconocida'}', style: const TextStyle(fontSize: 13)),
                Text(
                  'Creador: ${ruta['usuario']?['username'] ?? 'Anónimo'}',
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            if (isComment && commentText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Comentario: $commentText',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                ),
              ),
            if (isUserShare && sharedUser != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Compartido a: $sharedUser',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                ),
              ),
            if (isScore && scoreValue != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Puntaje otorgado:',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 4),
                    RatingBarIndicator(
                      rating: scoreValue,
                      itemBuilder: (context, _) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemCount: 5,
                      itemSize: 20.0,
                      direction: Axis.horizontal,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getUsuariosCompartidos(List<dynamic> rutasCreadas) {
    final List<Map<String, dynamic>> usuarios = [];

    for (var ruta in rutasCreadas) {
      if (ruta['compartida_con'] != null && ruta['compartida_con'].isNotEmpty) {
        for (var usuario in ruta['compartida_con']) {
          usuarios.add({
            'ruta': ruta,
            'usuario': usuario, // Incluye los detalles del usuario directamente
          });
        }
      }
    }

    return usuarios;
  }
}
