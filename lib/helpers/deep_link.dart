import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/pages/route/route_detail.dart';

class AppLinksDeepLink {
  AppLinksDeepLink._privateConstructor();

  static final AppLinksDeepLink _instance = AppLinksDeepLink._privateConstructor();

  static AppLinksDeepLink get instance => _instance;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle the initial link if the app was opened from a deep link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleIncomingLink(initialUri);
    }

    // Listen for incoming links while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) {
        _handleIncomingLink(uri);
      },
      onError: (err) {
        print('Error handling link: $err');
      },
    );
  }

  void _handleIncomingLink(Uri uri) {
    print('Received link: $uri');
    print('Path segments: ${uri.pathSegments}');

    // Your existing logic for handling incoming links
    if (uri.pathSegments.length >= 3) {
      final apiIndex = 0;
      final resourceIndex = 1;
      final actionIndex = 2;

      if (uri.pathSegments[apiIndex] == 'api') {
        if (uri.pathSegments[resourceIndex] == 'share' && uri.pathSegments[actionIndex] == 'route' && uri.pathSegments.length > 3) {
          // Navigate to the route detail screen
          _navigateToRouteDetail(uri.pathSegments[3]);
        } else if (uri.pathSegments[resourceIndex] == 'users' && uri.pathSegments[actionIndex] == 'confirm-email') {
          // Handle email confirmation
          _handleEmailConfirmation(uri);
        } else {
          print("Unrecognized route: ${uri.pathSegments}");
        }
      } else {
        print("The link does not belong to the expected endpoint.");
      }
    } else {
      print('The link does not have enough path segments.');
    }
  }

  void _navigateToRouteDetail(String routeId) {
    // Perform the request and navigate to the detail screen
    makeRequest(
      method: GET,
      url: ROUTE_DETAIL,
      urlVars: {'id': routeId},
      onOk: (response) {
        final data = jsonDecode(response.body);
        // Navigation using GetX
        Get.off(() => DetalleRutaScreen(ruta: data));
      },
      onError: (response) {
        final body = jsonDecode(response.body);
        Get.snackbar('Error', body['message']);
      },
    );
  }

  void _handleEmailConfirmation(Uri uri) {
    // Implement your email confirmation logic
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
