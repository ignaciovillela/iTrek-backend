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

    // Define regex patterns for different actions
    final shareRouteRegex = RegExp(r'^share/route/(\d+)$');
    final confirmEmailRegex = RegExp(r'^api/users/confirm-email$');

    // Combine path segments into a single string
    final path = uri.pathSegments.join('/');

    if (shareRouteRegex.hasMatch(path)) {
      // Extract route ID from the path using the regex
      final match = shareRouteRegex.firstMatch(path);
      final routeId = match?.group(1);
      if (routeId != null) {
        print('Navigating to route detail for route ID: $routeId');
        _navigateToRouteDetail(routeId);
      }
    } else if (confirmEmailRegex.hasMatch(path)) {
      // Handle email confirmation logic
      print('Handling email confirmation link');
      _handleEmailConfirmation(uri);
    } else {
      print('Unrecognized or invalid link: $path');
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
