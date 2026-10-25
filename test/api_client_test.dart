import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/core/api/auth_session.dart';
import 'package:glucomi/core/api/home_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(int status, Object body) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

Map<String, Object?> _ok(Object? result) => {
  'isSuccess': true,
  'code': 'COMMON_200',
  'message': '성공입니다.',
  'result': result,
};

void main() {
  final session = AuthSession.instance;

  tearDown(session.clear);

  test('성공 응답에서 result 만 꺼냄', () async {
    final client = ApiClient(
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        expect(request.url.path, '/api/terms');
        return _json(200, _ok([{'termsType': 'SERVICE'}]));
      }),
    );

    final result = await client.get('/api/terms', auth: false);

    expect(result, [
      {'termsType': 'SERVICE'},
    ]);
  });

  test('실패 응답은 서버 메시지로 ApiException', () async {
    final client = ApiClient(
      baseUrl: 'https://api.test',
      httpClient: MockClient(
        (_) async => _json(400, {
          'isSuccess': false,
          'code': 'MEAL_4000',
          'message': '단위가 올바르지 않습니다.',
          'result': null,
        }),
      ),
    );

    expect(
      () => client.post('/api/meal-records', body: const {}),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'MEAL_4000')
            .having((e) => e.message, 'message', '단위가 올바르지 않습니다.'),
      ),
    );
  });

  test('401 이면 토큰 재발급 후 다시 요청', () async {
    session.save(accessToken: 'old', refreshToken: 'refresh-1');
    final calls = <String>[];

    final client = ApiClient(
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        calls.add('${request.url.path} ${request.headers['Authorization']}');
        if (request.url.path == '/api/auth/reissue') {
          expect(jsonDecode(request.body), {'refreshToken': 'refresh-1'});
          return _json(
            200,
            _ok({'accessToken': 'new', 'refreshToken': 'refresh-2'}),
          );
        }
        if (request.headers['Authorization'] == 'Bearer old') {
          return _json(401, {
            'isSuccess': false,
            'code': 'COMMON_401',
            'message': '인증이 필요합니다.',
            'result': null,
          });
        }
        return _json(200, _ok({'memberId': 1}));
      }),
    );

    final result = await client.get('/api/members/me');

    expect(result, {'memberId': 1});
    expect(session.accessToken, 'new');
    expect(session.refreshToken, 'refresh-2');
    expect(calls, [
      '/api/members/me Bearer old',
      '/api/auth/reissue null',
      '/api/members/me Bearer new',
    ]);
  });

  test('홈 응답을 HomeData 로 바꿈', () async {
    session.save(accessToken: 'token');
    final client = ApiClient(
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        expect(request.url.queryParameters['date'], '2026-10-26');
        return _json(
          200,
          _ok({
            'date': '2026-10-26',
            'sensor': {'connected': true, 'provider': 'CARESENS_AIR', 'sensorDay': 3},
            'targetRange': {'min': 70, 'max': 180},
            'graph': {
              'points': [
                {'time': '2026-10-26T09:00:00', 'value': 120, 'trend': 4},
                {'time': '2026-10-26T08:55:00', 'value': 110, 'trend': 4},
              ],
              'minGlucose': 110,
              'maxGlucose': 120,
            },
            'summary': {
              'glucoseScore': 82,
              'glucoseScoreStatus': 'PROVISIONAL',
              'maxGlucose': 120,
              'averageGlucose': 115,
              'spikeCount': 0,
              'carbohydrateG': 45.5,
            },
            'meals': [
              {
                'mealRecordId': 1,
                'eatenAt': '2026-10-26T08:30:00',
                'representativeFoodName': '흑미밥',
                'itemCount': 3,
                'kcal': 412.4,
                'carbohydrateG': 45.5,
              },
            ],
          }),
        );
      }),
    );

    final data = await HomeApi(client).fetch(DateTime(2026, 10, 26));

    expect(data.sensorConnected, isTrue);
    expect(data.sensorDay, 3);
    expect(data.targetMin, 70);
    expect(data.targetMax, 180);
    expect(data.points.map((p) => p.value), [110, 120]);
    expect(data.score, 82);
    expect(data.averageGlucose, 115);
    expect(data.carbsGram, 45.5);
    expect(data.records.single.title, '흑미밥 외 2개');
    expect(data.records.single.details, ['총 412 kcal', '총 탄수화물 46 g']);
  });
}
