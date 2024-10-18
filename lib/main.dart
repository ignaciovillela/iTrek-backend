import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importa dotenv
import 'package:itrek_maps/pages/dashboard.dart';
import 'package:itrek_maps/pages/inicio.dart';
import 'package:itrek_maps/pages/login.dart';
import 'package:itrek_maps/pages/maps_google.dart';

import 'pages/listadoRutas.dart';

void main() async {
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MenuScreen());
  }
}
