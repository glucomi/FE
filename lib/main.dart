import 'package:flutter/material.dart';
import 'package:glucomi/core/api/api_config.dart';
import 'package:glucomi/core/api/auth_session.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:glucomi/features/signup/signup_flow.dart';
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
      home: const AppStart(),
      builder: (context, child) => PhoneFrame(child: child),
    );
  }
}
