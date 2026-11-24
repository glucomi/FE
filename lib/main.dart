import 'package:flutter/material.dart';
import 'package:glucomi/core/api/api_config.dart';
import 'package:glucomi/core/api/auth_session.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:glucomi/features/signup/signup_flow.dart';
import 'package:glucomi/features/splash/splash_screen.dart';
import 'package:glucomi/shared/app_scroll_behavior.dart';
import 'package:glucomi/shared/phone_frame.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (ApiConfig.kakaoNativeAppKey.isNotEmpty ||
      ApiConfig.kakaoJavaScriptKey.isNotEmpty) {
    await KakaoSdk.init(
      nativeAppKey: ApiConfig.kakaoNativeAppKey,
      javaScriptAppKey: ApiConfig.kakaoJavaScriptKey,
    );
  }
  await AuthSession.instance.restore();
  runApp(const GlucomiApp());
}

class GlucomiApp extends StatelessWidget {
  const GlucomiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '따당',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFFEFEFE),
      ),
      // MO-SPLASH-010 2000ms 뒤 로그인 상태에 맞는 첫 화면으로
      home: const SplashScreen(next: AppStart()),
      builder: (context, child) => PhoneFrame(child: child),
    );
  }
}
