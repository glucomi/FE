import 'package:flutter/material.dart';
import 'package:glucomi/features/signup/signup_flow.dart';
import 'package:glucomi/shared/app_scroll_behavior.dart';

void main() {
  runApp(const GlucomiApp());
}

class GlucomiApp extends StatelessWidget {
  const GlucomiApp({super.key});

  static const double _maxAppWidth = 480;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFFEFEFE),
      ),
      home: const SignupFlow(),
      // PC 브라우저처럼 화면이 넓으면 가운데 모바일 폭으로 보여줌
      builder: (context, child) => ColoredBox(
        color: const Color(0xFFF5F6F8),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxAppWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
