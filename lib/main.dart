import 'package:flutter/material.dart';
import 'package:glucomi/features/signup/signup_screen.dart';

void main() {
  runApp(const GlucomiApp());
}

class GlucomiApp extends StatelessWidget {
  const GlucomiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFFEFEFE),
      ),
      home: const SignupScreen(),
    );
  }
}
