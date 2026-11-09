import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/login/kakao_login_screen.dart';
import 'package:glucomi/features/signup/signup_flow.dart';
import 'package:glucomi/features/signup/signup_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues(<String, String>{});

  Future<void> pump(WidgetTester tester, {required bool kakao}) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: AppStart(kakaoLoginEnabled: kakao)),
    );
    await tester.pump();
  }

  testWidgets('카카오 키가 없으면 로그인 없이 약관 동의(MO-SIGNUP-010)부터', (
    tester,
  ) async {
    await pump(tester, kakao: false);
    expect(find.byType(SignupScreen), findsOneWidget);
    expect(find.byType(KakaoLoginScreen), findsNothing);
  });

  testWidgets('카카오 키가 있으면 MO-LOGIN-010 부터', (tester) async {
    await pump(tester, kakao: true);
    expect(find.byType(KakaoLoginScreen), findsOneWidget);
  });
}
