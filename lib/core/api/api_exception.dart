/// 서버 응답이 실패(isSuccess=false)거나 통신이 안 될 때
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  /// HTTP 상태 코드 (통신 자체가 실패하면 null)
  final int? statusCode;

  /// 서버 에러 코드 (예: COMMON_401, MEAL_4000)
  final String? code;

  /// 서버가 내려준 메시지 (없으면 기본 안내 문구)
  final String message;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}
