import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/deep_link.dart';
import 'package:itrek/pages/dashboard.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await db.initDatabase();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  final AppLinksHandler _appLinksHandler = AppLinksHandler.instance;

  @override
  Widget build(BuildContext context) {
    _appLinksHandler.initDeepLinks();

    return GetMaterialApp(
      scaffoldMessengerKey: scaffoldMessengerKey,
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
      home: DashboardScreen(),
    );
  }
}
