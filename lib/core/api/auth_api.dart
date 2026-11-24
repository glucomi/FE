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

/// GET /api/auth/kakao/authorize-url 결과
class KakaoAuthorizeUrl {
  const KakaoAuthorizeUrl({required this.authorizeUrl, required this.state});

  /// 카카오 로그인 페이지 주소 (그대로 연다)
  final String authorizeUrl;

  /// 인가 URL에 들어간 state — 콜백으로 돌아온 state와 비교
  final String state;
}

class AuthApi {
  AuthApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// 카카오 SDK 로 받은 카카오 access token 으로 로그인/가입 후 토큰 저장
  Future<LoginResult> loginWithKakao(String kakaoAccessToken) async {
    final json = await _client.post(
      '/api/auth/kakao',
      body: {'kakaoAccessToken': kakaoAccessToken},
      auth: false,
    ) as Map<String, dynamic>;
    await _client.session.save(
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

  /// 웹 카카오 로그인 페이지 주소 발급
  ///
  /// redirectUri 는 서버에 등록된 값만 가능 (그 외 400 AUTH_4000)
  Future<KakaoAuthorizeUrl> kakaoAuthorizeUrl(String redirectUri) async {
    final json = await _client.get(
      '/api/auth/kakao/authorize-url',
      query: {'redirectUri': redirectUri},
      auth: false,
    ) as Map<String, dynamic>;
    return KakaoAuthorizeUrl(
      authorizeUrl: json['authorizeUrl'] as String,
      state: json['state'] as String,
    );
  }

  /// Web OAuth: BE securely exchanges Kakao authorization code for Kakao token,
  /// then performs the same member lookup / JWT issuance as native login.
  Future<LoginResult> loginWithKakaoCode({
    required String authorizationCode,
    required String redirectUri,
  }) async {
    final json = await _client.post(
      '/api/auth/kakao/code',
      auth: false,
      body: {'code': authorizationCode, 'redirectUri': redirectUri},
    ) as Map<String, dynamic>;
    await _client.session.save(
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

  Future<void> logout() => _client.session.clear();
}
