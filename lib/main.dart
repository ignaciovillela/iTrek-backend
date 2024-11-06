import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'package:itrek/db.dart';
import 'package:itrek/pages/dashboard.dart';
import 'package:itrek/request.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await db.initDatabase();

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAppLinks();
  }

  Future<void> _initializeAppLinks() async {
    _appLinks = AppLinks();

    // Obtener el enlace inicial si la app fue abierta desde un enlace profundo
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleIncomingLink(initialUri);
    }

    // Escuchar enlaces entrantes mientras la app está en ejecución
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri);
    });
  }

  Future<void> _handleIncomingLink(Uri uri) async {
    // Imprimir el enlace recibido
    print('Enlace recibido: $uri');
    print('Segmentos del path: ${uri.pathSegments}');

    // Verificar que el enlace tiene los segmentos deseados
    if (uri.pathSegments.length >= 3 &&
        uri.pathSegments[0] == 'api' &&
        uri.pathSegments[1] == 'users' &&
        uri.pathSegments[2] == 'confirm-email') {
      // Hacer la solicitud si el enlace coincide
      makeRequest(
        method: GET,
        url: '${uri.toString()}?json=true',
        isFullUrl: true,
        onOk: (response) async {
          final data = jsonDecode(response.body);
          print('la data $data');
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Todo ok: $data')),
          );
          await db.values.createLoginData(data);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        },
        onError: (response) {
          final body = jsonDecode(response.body);
          print(body);
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text(body['message'])),
          );
        },
      );
    } else {
      print("El enlace no coincide con la estructura esperada.");
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const DashboardScreen(),
    );
  }
}
