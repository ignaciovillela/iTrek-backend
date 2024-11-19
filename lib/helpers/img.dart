
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;

final logoWhite = SvgPicture.asset(
  'assets/images/icon-black.svg',
  height: 30,
  colorFilter: ColorFilter.mode(
    Color(0xDDFFFFFF),
    BlendMode.srcIn,
  ),
);

Future<String?> downloadImageAsBase64(String imageUrl) async {
  try {
    final response = await http.get(Uri.parse(imageUrl));

    if (response.statusCode == 200) {
      String base64Image = base64Encode(response.bodyBytes);
      return base64Image;
    } else {
      print('Error al descargar la imagen: Código ${response.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error al descargar la imagen: $e');
    return null;
  }
}
