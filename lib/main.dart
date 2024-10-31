import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:itrek/db.dart';
import 'package:itrek/pages/dashboard.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  await db.initDatabase();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: MenuScreen());
  }
}
