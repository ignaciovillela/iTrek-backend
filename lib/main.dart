import 'package:flutter/material.dart';
import 'pages/login.dart'; // Importar la página que contiene el mapa
import 'pages/listadoRutas.dart';
import 'pages/maps_google.dart';
import 'pages/recorrerRuta.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ListadoRutasScreen(), // Llama a la nueva página de Google Maps
    );
  }
}
