import 'package:flutter/foundation.dart';
import 'package:glucomi/core/api/api_config.dart';

/// 로그인 토큰 보관 (앱 전체에서 하나)
///
/// 지금은 메모리에만 들고 있어서 새로고침하면 사라짐.
/// 카카오 로그인 화면을 붙일 때 기기 저장(shared_preferences 등)으로 바꾸면 됨
class AuthSession extends ChangeNotifier {
  AuthSession._()
    : _accessToken = ApiConfig.devAccessToken.isEmpty
          ? null
          : ApiConfig.devAccessToken,
      _refreshToken = ApiConfig.devRefreshToken.isEmpty
          ? null
          : ApiConfig.devRefreshToken;

  static final AuthSession instance = AuthSession._();

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  /// 토큰이 있으면 서버 API 를 쓰고, 없으면 화면은 예시 데이터로 동작
  bool get isLoggedIn => _accessToken != null;

  void save({required String accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken ?? _refreshToken;
    notifyListeners();
  }

  void clear() {
    if (_accessToken == null && _refreshToken == null) return;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }
}
