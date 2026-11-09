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
  static const String kakaoRedirectUri = String.fromEnvironment(
    'KAKAO_REDIRECT_URI',
  );

  /// 카카오 로그인(MO-LOGIN-010)을 쓸 수 있는 빌드인지
  ///
  /// 키가 없으면 로그인 화면 없이 약관 동의(MO-SIGNUP-010)부터 시작함
  /// (서버 웹 로그인·CORS 준비 전까지 이 상태로 배포)
  static bool get kakaoLoginEnabled => kIsWeb
      ? kakaoRestApiKey.isNotEmpty && kakaoRedirectUri.isNotEmpty
      : kakaoNativeAppKey.isNotEmpty;

  static const Duration timeout = Duration(seconds: 15);
}
