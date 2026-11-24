import 'package:flutter/foundation.dart';

/// 서버 주소와 개발용 토큰 설정
///
/// 실행 시 `--dart-define` 으로 바꿀 수 있음
/// 예) flutter run -d chrome --dart-define=DEV_ACCESS_TOKEN=eyJ...
abstract final class ApiConfig {
  /// DDADNG API 서버 (Swagger: /swagger-ui/index.html)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://54-116-228-101.sslip.io',
  );

  /// 카카오 로그인 화면이 붙기 전까지 테스트용으로 넣는 JWT
  static const String devAccessToken = String.fromEnvironment(
    'DEV_ACCESS_TOKEN',
  );
  static const String devRefreshToken = String.fromEnvironment(
    'DEV_REFRESH_TOKEN',
  );

  // Kakao native app key is a public app identifier (not the client secret).
  static const String kakaoNativeAppKey = String.fromEnvironment(
    'KAKAO_NATIVE_APP_KEY',
  );
  static const String kakaoJavaScriptKey = String.fromEnvironment(
    'KAKAO_JAVASCRIPT_KEY',
  );
  static const String kakaoRestApiKey = String.fromEnvironment(
    'KAKAO_REST_API_KEY',
  );
  static const String _kakaoRedirectUriOverride = String.fromEnvironment(
    'KAKAO_REDIRECT_URI',
  );

  /// 카카오 콘솔·BE 에 등록된 콜백 경로
  /// (https://ddadang.vercel.app/auth/kakao/callback, http://localhost:5000/auth/kakao/callback)
  static const String kakaoCallbackPath = '/auth/kakao/callback';

  /// 카카오 인가 요청과 BE 코드 교환에 같은 값을 넣어야 함.
  /// --dart-define 이 없으면 지금 열린 주소 + 콜백 경로 (배포·로컬 5000 둘 다 자동으로 맞음)
  static String get kakaoRedirectUri {
    if (_kakaoRedirectUriOverride.isNotEmpty) return _kakaoRedirectUriOverride;
    if (!kIsWeb) return '';
    return '${Uri.base.origin}$kakaoCallbackPath';
  }

  /// 카카오 로그인(MO-LOGIN-010)을 쓸 수 있는 빌드인지
  ///
  /// 웹은 서버가 인가 URL을 만들어 주므로 항상 가능.
  /// 앱(네이티브)은 KAKAO_NATIVE_APP_KEY 가 없으면 약관 동의(MO-SIGNUP-010)부터 시작
  static bool get kakaoLoginEnabled => kIsWeb || kakaoNativeAppKey.isNotEmpty;

  static const Duration timeout = Duration(seconds: 15);
}
