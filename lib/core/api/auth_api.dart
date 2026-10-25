import 'package:glucomi/core/api/api_client.dart';

/// POST /api/auth/kakao 결과
class LoginResult {
  const LoginResult({
    required this.memberId,
    required this.isNewMember,
    required this.signupCompleted,
    required this.onboardingCompleted,
  });

  final int memberId;
  final bool isNewMember;

  /// false 면 약관 동의(MO-SIGNUP)로
  final bool signupCompleted;

  /// false 면 큐레이션(MO-CURATION)으로
  final bool onboardingCompleted;
}

class AuthApi {
  AuthApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// 카카오 SDK 로 받은 카카오 access token 으로 로그인/가입 후 토큰 저장
  Future<LoginResult> loginWithKakao(String kakaoAccessToken) async {
    final json =
        await _client.post(
              '/api/auth/kakao',
              body: {'kakaoAccessToken': kakaoAccessToken},
              auth: false,
            )
            as Map<String, dynamic>;
    _client.session.save(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String?,
    );
    return LoginResult(
      memberId: asInt(json['memberId']) ?? 0,
      isNewMember: json['isNewMember'] == true,
      signupCompleted: json['signupCompleted'] == true,
      onboardingCompleted: json['onboardingCompleted'] == true,
    );
  }

  void logout() => _client.session.clear();
}
