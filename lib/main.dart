import 'package:flutter/material.dart';
import 'package:glucomi/features/signup/signup_flow.dart';
import 'package:glucomi/shared/app_scroll_behavior.dart';

void main() {
  runApp(const GlucomiApp());
}

class GlucomiApp extends StatelessWidget {
  const GlucomiApp({super.key});

  /// Figma 화면 크기
  static const Size _designSize = Size(360, 800);

  /// 이보다 넓으면 PC 로 보고 폰 크기로 고정
  static const double _phoneMaxWidth = 600;

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
      // PC 브라우저처럼 화면이 넓으면 Figma 기준 360x800 폰 크기로 가운데 고정
      // (창이 작으면 비율 유지한 채 축소). 폰에서는 화면 전체 사용
      builder: (context, child) {
        final screen = MediaQuery.sizeOf(context);
        if (screen.width <= _phoneMaxWidth) {
          return child ?? const SizedBox.shrink();
        }
        return ColoredBox(
          color: const Color(0xFFF5F6F8),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox.fromSize(
                size: _designSize,
                child: ClipRect(
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      size: _designSize,
                      padding: EdgeInsets.zero,
                      viewPadding: EdgeInsets.zero,
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
