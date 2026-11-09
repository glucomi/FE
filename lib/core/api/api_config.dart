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

  static const Duration timeout = Duration(seconds: 15);
}
