import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glucomi/core/api/api_config.dart';
import 'package:glucomi/core/api/auth_api.dart';
import 'package:glucomi/features/login/callback_url.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart'
    hide AuthApi;
import 'package:url_launcher/url_launcher.dart';

class KakaoLoginCancelled implements Exception {
  const KakaoLoginCancelled();
}

/// Native: Kakao SDK -> Kakao access token -> BE JWT.
/// Web: Kakao authorize redirect -> BE exchanges code -> BE JWT.
/// The web flow requires the BE /api/auth/kakao/code endpoint.
class KakaoOAuthFlow {
  KakaoOAuthFlow({AuthApi? api}) : _api = api ?? AuthApi();
  final AuthApi _api;
  static const _storage = FlutterSecureStorage();
  static const _stateKey = 'ddadang_kakao_oauth_state';

  Future<void> login() async {
    if (kIsWeb) return _startWeb();
    if (ApiConfig.kakaoNativeAppKey.isEmpty) {
      throw StateError('KAKAO_NATIVE_APP_KEY를 설정해주세요.');
    }
    OAuthToken token;
    if (await isKakaoTalkInstalled()) {
      try {
        token = await UserApi.instance.loginWithKakaoTalk();
      } on PlatformException catch (e) {
        if (e.code == 'CANCELED') throw const KakaoLoginCancelled();
        token = await UserApi.instance.loginWithKakaoAccount();
      } catch (_) {
        token = await UserApi.instance.loginWithKakaoAccount();
      }
    } else {
      token = await UserApi.instance.loginWithKakaoAccount();
    }
    await _api.loginWithKakao(token.accessToken);
  }

  Future<void> _startWeb() async {
    if (ApiConfig.kakaoRestApiKey.isEmpty ||
        ApiConfig.kakaoRedirectUri.isEmpty) {
      throw StateError('KAKAO_REST_API_KEY와 KAKAO_REDIRECT_URI를 설정해주세요.');
    }
    // A cryptographically random state mitigates login CSRF and is checked
    // after the full-page redirect using secure, same-origin storage.
    final random = Random.secure();
    final state = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _storage.write(key: _stateKey, value: state);
    final uri = Uri.https('kauth.kakao.com', '/oauth/authorize', {
      'response_type': 'code',
      'client_id': ApiConfig.kakaoRestApiKey,
      'redirect_uri': ApiConfig.kakaoRedirectUri,
      'state': state,
    });
    if (!await launchUrl(uri, webOnlyWindowName: '_self')) {
      throw StateError('카카오 인증 페이지를 열지 못했어요.');
    }
  }

  bool get hasWebCallback =>
      kIsWeb &&
      (Uri.base.queryParameters.containsKey('code') ||
          Uri.base.queryParameters.containsKey('error'));

  Future<void> completeWebLogin() async {
    final params = Uri.base.queryParameters;
    // 성공·실패와 관계없이 인가 코드는 한 번만 쓰므로 주소에서 바로 지움
    clearOAuthCallbackFromUrl();
    if (params.containsKey('error')) {
      await _storage.delete(key: _stateKey);
      if (params['error'] == 'access_denied') throw const KakaoLoginCancelled();
      throw StateError('카카오 인증이 완료되지 않았어요.');
    }
    final code = params['code'];
    final state = params['state'];
    final expected = await _storage.read(key: _stateKey);
    await _storage.delete(key: _stateKey);
    if (code == null ||
        code.isEmpty ||
        state == null ||
        expected == null ||
        state != expected) {
      throw StateError('카카오 로그인 요청을 확인할 수 없어요. 다시 시도해 주세요.');
    }
    await _api.loginWithKakaoCode(
      authorizationCode: code,
      redirectUri: ApiConfig.kakaoRedirectUri,
    );
  }
}
