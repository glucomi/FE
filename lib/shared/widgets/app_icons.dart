import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppChevronRight extends StatelessWidget {
  const AppChevronRight({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/signup/chevron_right.svg');
  }
}

class AppChevronLeft extends StatelessWidget {
  const AppChevronLeft({super.key});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset('assets/signup/back.svg');
  }
}
