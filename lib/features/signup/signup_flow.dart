import 'package:flutter/material.dart';
import 'package:glucomi/features/curation/curation_screen.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/home/home_screen.dart';
import 'package:glucomi/features/signup/signup_screen.dart';

/// 회원가입 약관 동의 → 큐레이션 → 홈으로 이어지는 흐름
class SignupFlow extends StatelessWidget {
  const SignupFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return SignupScreen(
      onSubmit: (consent) async {
        // 약관 동의 내역 저장 API는 백엔드 연동 시 추가
        final navigator = Navigator.of(context);
        navigator.push(
          PageRouteBuilder<void>(
            // Figma 기준 큐레이션 1단계는 뒤로가기 없음
            pageBuilder: (_, _, _) => CurationScreen(
              // 큐레이션 결과 저장 API는 백엔드 연동 시 추가
              onComplete: (result) async {
                navigator.pushAndRemoveUntil(
                  PageRouteBuilder<void>(
                    pageBuilder: (_, _, _) => HomeScreen(
                      data: HomeData.empty(
                        targetMin: result.targetMin,
                        targetMax: result.targetMax,
                      ),
                    ),
                    transitionDuration: Duration.zero,
                    reverseTransitionDuration: Duration.zero,
                  ),
                  (_) => false,
                );
              },
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }
}
