import 'package:flutter/material.dart';
import 'package:glucomi/core/api/auth_session.dart';
import 'package:glucomi/core/api/member_api.dart';
import 'package:glucomi/features/curation/curation_models.dart';
import 'package:glucomi/features/curation/curation_screen.dart';
import 'package:glucomi/features/home/home_loader.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/home/home_screen.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/signup/signup_screen.dart';
import 'package:glucomi/features/weight/weight_models.dart';

/// 앱 첫 화면
///
/// - 로그인 토큰이 있으면 GET /api/members/me 로 가입/온보딩 상태를 보고
///   약관 동의 / 큐레이션 / 홈 중 알맞은 곳에서 시작
/// - 토큰이 없으면(카카오 로그인 연결 전) 지금처럼 예시 데이터로 흐름만 보여줌
class AppStart extends StatefulWidget {
  const AppStart({super.key, this.memberApi});

  final MemberApi? memberApi;

  @override
  State<AppStart> createState() => _AppStartState();
}

class _AppStartState extends State<AppStart> {
  Future<MemberInfo>? _me;

  @override
  void initState() {
    super.initState();
    if (AuthSession.instance.isLoggedIn) {
      _me = (widget.memberApi ?? MemberApi()).me();
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = _me;
    if (me == null) return const SignupFlow();

    return FutureBuilder<MemberInfo>(
      future: me,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final info = snapshot.data;
        // 내 정보를 못 불러오면(토큰 만료 등) 처음 흐름으로
        if (info == null || !info.signupCompleted) return const SignupFlow();
        if (!info.onboardingCompleted) {
          return const SignupFlow(startAtCuration: true);
        }
        return HomeLoader(targetMin: info.targetMin, targetMax: info.targetMax);
      },
    );
  }
}

/// 회원가입 약관 동의 → 큐레이션 → 홈으로 이어지는 흐름
class SignupFlow extends StatelessWidget {
  const SignupFlow({super.key, this.startAtCuration = false, this.memberApi});

  /// 약관 동의는 끝났고 큐레이션부터 해야 할 때
  final bool startAtCuration;

  final MemberApi? memberApi;

  bool get _online => AuthSession.instance.isLoggedIn;

  MemberApi get _api => memberApi ?? MemberApi();

  @override
  Widget build(BuildContext context) {
    if (startAtCuration) return _curation(Navigator.of(context));

    return SignupScreen(
      onSubmit: (consent) async {
        final navigator = Navigator.of(context);
        // 실패하면 약관 화면이 가입 실패 안내를 띄움
        if (_online) await _api.agree(consent);
        navigator.push(
          PageRouteBuilder<void>(
            // Figma 기준 큐레이션 1단계는 뒤로가기 없음
            pageBuilder: (_, _, _) => _curation(navigator),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
    );
  }

  Widget _curation(NavigatorState navigator) {
    return CurationScreen(
      onComplete: (result) async {
        // 실패하면 큐레이션 화면이 저장 실패 안내를 띄움
        if (_online) await _api.saveOnboarding(result);
        navigator.pushAndRemoveUntil(
          PageRouteBuilder<void>(
            pageBuilder: (_, _, _) => _home(result),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
          (_) => false,
        );
      },
    );
  }

  Widget _home(CurationResult result) {
    if (_online) {
      return HomeLoader(targetMin: result.targetMin, targetMax: result.targetMax);
    }
    return HomeScreen(
      data: HomeData.empty(
        targetMin: result.targetMin,
        targetMax: result.targetMax,
      ),
      // 로그인 전에는 예시 음식 데이터 사용
      mealRepository: SampleMealFoodRepository(),
      // 체중 API 가 없어서 메모리 저장소 사용
      weightRepository: SampleWeightRepository(),
    );
  }
}
