import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:itrek/helpers/db.dart';
import 'package:itrek/helpers/request.dart';
import 'package:itrek/pages/dashboard.dart';
import 'package:itrek/pages/route/route_detail.dart';
import 'package:itrek/main.dart';

class AppLinksHandler {
  AppLinksHandler._privateConstructor();

  static final AppLinksHandler _instance = AppLinksHandler._privateConstructor();

  static AppLinksHandler get instance => _instance;

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  void initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle the initial link if the app was opened from a deep link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _routeDeepLink(initialUri);
    }

    // Listen for incoming links while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
          (uri) {
        _routeDeepLink(uri);
      },
      onError: (err) {
        print('Error handling link: $err');
      },
    );
  }

  void _routeDeepLink(Uri uri) {
    print('Received link: $uri');
    print('Path segments: ${uri.pathSegments}');

    final path = uri.pathSegments.join('/');
    if (RegExp(r'^share/route/(\d+)$').hasMatch(path)) {
      final routeId = RegExp(r'^share/route/(\d+)$').firstMatch(path)?.group(1);
      if (routeId != null) {
        _navigateToRouteDetail(routeId);
      }
    } else if (RegExp(r'^api/users/confirm-email/(\w+)/$').hasMatch(path)) {
      _handleEmailConfirmation(uri);
    } else if (RegExp(r'^confirmed/users/email$').hasMatch(path)) {
      _handleConfirmedEmail(uri);
    } else {
      print('Unrecognized or invalid link: $path');
    }
  }

  void _navigateToRouteDetail(String routeId) {
    makeRequest(
      method: GET,
      url: ROUTE_DETAIL,
      urlVars: {'id': routeId},
      onOk: (response) {
        final data = jsonDecode(response.body);
        Get.off(() => DetalleRutaScreen(ruta: data));
      },
      onError: (response) {
        final body = jsonDecode(response.body);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error: ${body['message']}')),
        );
      },
    );
  }

  void _handleEmailConfirmation(Uri uri) {
    makeRequest(
      method: GET,
      url: '${uri.toString()}?json=true',
      isFullUrl: true,
      onOk: (response) async {
        final data = jsonDecode(response.body);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Confirmación exitosa para ${data['username']}')),
        );
        await db.values.setUserData(data);
        Get.off(() => DashboardScreen());
      },
      onError: (response) {
        final body = jsonDecode(response.body);
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Error: ${body['message']}')),
        );
      },
    );
  }

  void _handleConfirmedEmail(Uri uri) {
    final queryParams = uri.queryParameters;

    if (queryParams['username'] == null || queryParams['email'] == null || queryParams['token'] == null) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Faltan parámetros en el enlace de confirmación.')),
      );
      return;
    }

    final fields = {
      'username': queryParams['username'],
      'email': queryParams['email'],
      'first_name': queryParams['first_name'],
      'last_name': queryParams['last_name'],
      'biografia': queryParams['biografia'],
      'imagen_perfil': queryParams['imagen_perfil'],
      'token': queryParams['token'],
    };

    print('Datos recibidos: $fields');

    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('Confirmación exitosa para ${fields['username']}')),
    );

    db.values.setUserData(fields);
    Get.off(() => DashboardScreen());
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
