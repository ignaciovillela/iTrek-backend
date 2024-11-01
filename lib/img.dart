
import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';

final logoWhite = SvgPicture.asset(
  'assets/images/icon-black.svg',
  height: 30,
  colorFilter: ColorFilter.mode(
    Color(0xDDFFFFFF),
    BlendMode.srcIn,
  ),
);