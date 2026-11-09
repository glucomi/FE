import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glucomi/core/api/api_config.dart';

/// 로그인 토큰 보관 (앱 전체에서 하나)
///
/// JWT는 플랫폼 보안 저장소에 보관하고 앱 시작 시 복원한다.
/// 토큰은 URL, 로그, 일반 설정값 저장소에 저장하지 않는다.
class AuthSession extends ChangeNotifier {
  AuthSession._()
    : _accessToken = ApiConfig.devAccessToken.isEmpty
          ? null
          : ApiConfig.devAccessToken,
      _refreshToken = ApiConfig.devRefreshToken.isEmpty
          ? null
          : ApiConfig.devRefreshToken;

  static final AuthSession instance = AuthSession._();
  static const _secure = FlutterSecureStorage();
  static const _accessKey = 'ddadang_access_token';
  static const _refreshKey = 'ddadang_refresh_token';

  /// 앱 최초 실행 시 main()에서 await. 개발용 토큰이 있으면 그 값을 우선한다.
  Future<void> restore() async {
    if (ApiConfig.devAccessToken.isNotEmpty) return;
    try {
      _accessToken = await _secure.read(key: _accessKey);
      _refreshToken = await _secure.read(key: _refreshKey);
      notifyListeners();
    } catch (_) {
      _accessToken = null;
      _refreshToken = null;
      notifyListeners();
    }
  }

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// 토큰이 있으면 서버 API 를 쓰고, 없으면 화면은 예시 데이터로 동작
  bool get isLoggedIn => _accessToken != null;

  Future<void> save({required String accessToken, String? refreshToken}) async {
    await _secure.write(key: _accessKey, value: accessToken);
    if (refreshToken != null) {
      await _secure.write(key: _refreshKey, value: refreshToken);
    }
    _accessToken = accessToken;
    _refreshToken = refreshToken ?? _refreshToken;
    notifyListeners();
  }

  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
    await _secure.delete(key: _accessKey);
    await _secure.delete(key: _refreshKey);
  }
}
