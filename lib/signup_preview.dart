import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glucomi/features/signup/signup_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SignupPreviewApp());
}

class SignupPreviewApp extends StatelessWidget {
  const SignupPreviewApp({super.key});

  static const Size _designSize = Size(360, 800);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const SignupScreen(),
      builder: (context, child) {
        if (!kIsWeb) {
          return child ?? const SizedBox.shrink();
        }

        final mediaQuery = MediaQuery.of(context).copyWith(
          size: _designSize,
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
          viewInsets: EdgeInsets.zero,
        );

        return ColoredBox(
          color: const Color(0xFFF5F6F8),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: _designSize.width,
              height: _designSize.height,
              child: ClipRect(
                child: MediaQuery(
                  data: mediaQuery,
                  child: child ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
