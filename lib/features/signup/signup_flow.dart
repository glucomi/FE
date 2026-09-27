import 'package:flutter/material.dart';
import 'package:glucomi/features/curation/curation_screen.dart';
import 'package:glucomi/features/signup/signup_screen.dart';

/// 회원가입 약관 동의 → 큐레이션으로 이어지는 흐름
class SignupFlow extends StatelessWidget {
  const SignupFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return SignupScreen(
      onSubmit: (consent) async {
        // 약관 동의 내역 저장 API는 백엔드 연동 시 추가
        Navigator.of(context).push(
          PageRouteBuilder<void>(
            // Figma 기준 큐레이션 1단계는 뒤로가기 없음
            pageBuilder: (_, _, _) => const CurationScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
