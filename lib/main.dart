import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:itrek/db.dart';
import 'package:itrek/pages/dashboard.dart';
import 'package:itrek/request.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await db.initDatabase();

  runApp(const MyApp());
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
    print('Enlace recibido: $uri');
    print('Segmentos del path: ${uri.pathSegments}');

    if (uri.pathSegments.length >= 3 &&
        uri.pathSegments[0] == 'api' &&
        uri.pathSegments[1] == 'users' &&
        uri.pathSegments[2] == 'confirm-email') {
      makeRequest(
        method: GET,
        url: '${uri.toString()}?json=true',
        isFullUrl: true,
        onOk: (response) async {
          final data = jsonDecode(response.body);
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Todo ok: ${data['message']}')),
          );
          await db.values.setUserData(data);

          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (context) => DashboardScreen()),
          );
        },
        onError: (response) {
          final body = jsonDecode(response.body);
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
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.light,
            primary: Color(0xFF338855),
            onPrimary: Colors.white,
            secondary: Color(0xFF55AA77),
            onSecondary: Colors.white,
            tertiary: Color(0xFF88C09E),
            onTertiary: Colors.white,
            background: Color(0xFFF1F8F5),
            onBackground: Color(0xFF1A1A1A),
            surface: Color(0xFFFFFFFF),
            onSurface: Color(0xFF333333),
            error: Color(0xFFB00020),
            onError: Colors.white,
            primaryContainer: Color(0xFFB3E5C9),
            onPrimaryContainer: Color(0xFF002D13),
            secondaryContainer: Color(0xFFD7F3E4),
            onSecondaryContainer: Color(0xFF00362E),
            tertiaryContainer: Color(0xFFBFEBD9),
            onTertiaryContainer: Color(0xFF00251A),
          ),
        ),
      home: const DashboardScreen(),
    );
  }
}
