import 'dart:async';
import 'dart:convert';

import 'package:glucomi/core/api/api_config.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/core/api/auth_session.dart';
import 'package:http/http.dart' as http;

/// DDADNG 서버 공통 호출기
///
/// - 응답 래퍼 `{isSuccess, code, message, result}` 에서 result 만 꺼내 줌
/// - 로그인 토큰을 Authorization 헤더에 붙임
/// - 401 이면 refresh token 으로 한 번 재발급 후 다시 요청
class ApiClient {
  ApiClient({
    http.Client? httpClient,
    AuthSession? session,
    String baseUrl = ApiConfig.baseUrl,
  }) : _http = httpClient ?? http.Client(),
       _session = session ?? AuthSession.instance,
       _baseUrl = baseUrl;

  static final ApiClient instance = ApiClient();

  final http.Client _http;
  final AuthSession _session;
  final String _baseUrl;

  /// 동시에 여러 요청이 401 을 받아도 재발급은 한 번만
  Future<bool>? _reissuing;

  AuthSession get session => _session;

  Future<dynamic> get(
    String path, {
    Map<String, Object?>? query,
    bool auth = true,
  }) => _send('GET', path, query: query, auth: auth);

  Future<dynamic> post(
    String path, {
    Object? body,
    Map<String, Object?>? query,
    bool auth = true,
  }) => _send('POST', path, body: body, query: query, auth: auth);

  Future<dynamic> put(String path, {Object? body, bool auth = true}) =>
      _send('PUT', path, body: body, auth: auth);

  Future<dynamic> delete(String path, {bool auth = true}) =>
      _send('DELETE', path, auth: auth);

  Uri _uri(String path, Map<String, Object?>? query) {
    final params = <String, String>{
      for (final MapEntry(:key, :value) in (query ?? const {}).entries)
        if (value != null) key: value.toString(),
    };
    return Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: params.isEmpty ? null : params);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    Map<String, Object?>? query,
    required bool auth,
    bool retried = false,
  }) async {
    final request = http.Request(method, _uri(path, query))
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json; charset=utf-8';
      request.body = jsonEncode(body);
    }
    final token = _session.accessToken;
    if (auth && token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final http.Response response;
    try {
      final streamed = await _http.send(request).timeout(ApiConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(message: '서버 응답이 늦어요. 잠시 후 다시 시도해 주세요.');
    } catch (_) {
      throw const ApiException(message: '네트워크 연결을 확인해 주세요.');
    }

    if (response.statusCode == 401 && auth && !retried && await _reissue()) {
      return _send(
        method,
        path,
        body: body,
        query: query,
        auth: auth,
        retried: true,
      );
    }

    return _unwrap(response);
  }

  dynamic _unwrap(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    Object? json;
    if (text.isNotEmpty) {
      try {
        json = jsonDecode(text);
      } on FormatException {
        json = null;
      }
    }

    final ok = response.statusCode >= 200 && response.statusCode < 300;
    if (json is Map<String, dynamic> && json.containsKey('isSuccess')) {
      if (ok && json['isSuccess'] == true) return json['result'];
      throw ApiException(
        statusCode: response.statusCode,
        code: json['code'] as String?,
        message: (json['message'] as String?) ?? '요청을 처리하지 못했어요.',
      );
    }
    if (ok) return json;
    throw ApiException(
      statusCode: response.statusCode,
      message: '요청을 처리하지 못했어요. (${response.statusCode})',
    );
  }

  Future<bool> _reissue() {
    final refresh = _session.refreshToken;
    if (refresh == null) return Future.value(false);
    return _reissuing ??= () async {
      try {
        final result = await _send(
          'POST',
          '/api/auth/reissue',
          body: {'refreshToken': refresh},
          auth: false,
        );
        final map = result as Map<String, dynamic>;
        _session.save(
          accessToken: map['accessToken'] as String,
          refreshToken: map['refreshToken'] as String?,
        );
        return true;
      } catch (_) {
        // refresh token 도 만료 → 다시 로그인해야 함
        _session.clear();
        return false;
      } finally {
        _reissuing = null;
      }
    }();
  }
}

/// 서버 날짜 파라미터 (yyyy-MM-dd)
String formatApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// 서버 일시 파라미터 (yyyy-MM-ddTHH:mm:ss, 기기 시간대 = KST 기준)
String formatApiDateTime(DateTime time) {
  final t = time.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${formatApiDate(t)}T${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}

/// 서버 일시 응답을 기기 시간으로 (오프셋이 붙어 와도 처리)
DateTime parseApiDateTime(String value) => DateTime.parse(value).toLocal();

/// 숫자 응답 (int/double 섞여 와도 처리)
double? asDouble(Object? value) => (value as num?)?.toDouble();
int? asInt(Object? value) => (value as num?)?.toInt();
