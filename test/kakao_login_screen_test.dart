import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/login/kakao_login_screen.dart';
import 'package:glucomi/features/login/kakao_oauth_flow.dart';

class _TestLoginFlow extends KakaoOAuthFlow {
  bool called = false;

  @override
  Future<void> login() async {
    called = true;
  }
}

void main() {
  testWidgets('MO-LOGIN-010: 카카오 버튼에서 로그인 로직 호출', (tester) async {
    tester.view.physicalSize = const Size(360, 779);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final flow = _TestLoginFlow();
    await tester.pumpWidget(MaterialApp(home: KakaoLoginScreen(flow: flow)));

    expect(find.text('따끔한 당뇨 코치'), findsOneWidget);
    expect(find.text('따당'), findsOneWidget);
    expect(find.byKey(const ValueKey('kakao-login-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('kakao-login-button')));
    await tester.pumpAndSettle();
    expect(flow.called, isTrue);
  });
}
