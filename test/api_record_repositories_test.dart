import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/features/exercise/api_exercise_repository.dart';
import 'package:glucomi/features/exercise/exercise_models.dart';
import 'package:glucomi/features/insulin/api_insulin_repository.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/features/meal/api_meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/memo/api_memo_repository.dart';
import 'package:glucomi/features/memo/memo_models.dart';
import 'package:glucomi/features/weight/api_weight_repository.dart';
import 'package:glucomi/features/weight/weight_models.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(int status, Object? result, {bool ok = true}) =>
    http.Response.bytes(
      utf8.encode(
        jsonEncode({
          'isSuccess': ok,
          'code': ok ? 'COMMON_200' : 'ERROR',
          'message': ok ? '성공입니다.' : '실패',
          'result': result,
        }),
      ),
      status,
      headers: {'content-type': 'application/json'},
    );

/// 요청을 기록하고 [handler] 로 응답하는 클라이언트
(ApiClient, List<http.Request>) _client(
  http.Response Function(http.Request request) handler,
) {
  final requests = <http.Request>[];
  final client = ApiClient(
    baseUrl: 'https://api.test',
    httpClient: MockClient((request) async {
      requests.add(request);
      return handler(request);
    }),
  );
  return (client, requests);
}

Map<String, dynamic> _body(http.Request r) =>
    jsonDecode(r.body) as Map<String, dynamic>;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues(<String, String>{});

  group('체중 (MO-WEIGHT-010)', () {
    test('날짜 경로로 PUT 하고 weightKg 를 보냄', () async {
      final (client, requests) = _client((_) => _json(200, null));
      await ApiWeightRepository(client)
          .save(WeightRecord(date: DateTime(2026, 11, 9), kg: 52.3));

      expect(requests.single.method, 'PUT');
      expect(requests.single.url.path, '/api/weight-records/2026-11-09');
      expect(_body(requests.single), {'weightKg': 52.3});
    });

    test('기록이 없으면 null', () async {
      final (client, _) = _client((_) => _json(200, null));
      expect(
        await ApiWeightRepository(client).byDate(DateTime(2026, 11, 9)),
        isNull,
      );
    });
  });

  group('운동 (MO-EXERCISE-010)', () {
    const walk = Exercise(id: '1', name: '걷기', kcalPerBase: 65);
    const run = Exercise(id: '2', name: '달리기', kcalPerBase: 240);

    test('운동이 여러 개면 운동마다 기록을 만들고 id 를 묶음', () async {
      var next = 10;
      final (client, requests) = _client(
        (_) => _json(200, {'exerciseRecordId': next++}),
      );
      final saved = await ApiExerciseRepository(client).save(
        ExerciseRecord(
          time: DateTime(2026, 11, 9, 19),
          entries: const [
            ExerciseEntry(exercise: walk, minutes: 30),
            ExerciseEntry(exercise: run, minutes: 20),
          ],
          memo: '저녁 운동',
        ),
      );

      expect(saved.id, '10,11');
      expect(requests.map((r) => r.method), ['POST', 'POST']);
      expect(_body(requests.first), {
        'exerciseId': 1,
        'performedAt': '2026-11-09T19:00:00',
        'durationMin': 30,
        'memo': '저녁 운동',
      });
    });

    test('묶인 기록 삭제는 서버 기록을 모두 삭제', () async {
      final (client, requests) = _client((_) => _json(200, null));
      await ApiExerciseRepository(client).delete('10,11');
      expect(requests.map((r) => r.url.path), [
        '/api/exercise-records/10',
        '/api/exercise-records/11',
      ]);
    });

    test('30분 칼로리는 kcalPer30Min 을 씀', () async {
      final (client, _) = _client(
        (_) => _json(200, [
          {'exerciseId': 1, 'name': '걷기', 'kcalPer30Min': 64.6},
        ]),
      );
      final list = await ApiExerciseRepository(client).catalog();
      expect(list.single.kcalPerBase, 65);
    });
  });

  group('메모 (MO-MEMO-010)', () {
    test('내용을 content 로 저장', () async {
      final (client, requests) = _client(
        (_) => _json(200, {
          'memoRecordId': 3,
          'recordedAt': '2026-11-09T21:00:00',
          'content': '늦은 저녁',
        }),
      );
      final saved = await ApiMemoRepository(client)
          .save(MemoRecord(time: DateTime(2026, 11, 9, 21), text: ' 늦은 저녁 '));
      expect(saved.id, '3');
      expect(_body(requests.single), {
        'recordedAt': '2026-11-09T21:00:00',
        'content': '늦은 저녁',
      });
    });

    test('사진만 있는 메모는 서버 호출 없이 안내', () async {
      final (client, requests) = _client((_) => _json(200, null));
      await expectLater(
        ApiMemoRepository(client).save(
          MemoRecord(
            time: DateTime(2026, 11, 9),
            photos: [MemoPhoto(utf8.encode('x'))],
          ),
        ),
        throwsA(isA<ApiException>()),
      );
      expect(requests, isEmpty);
    });
  });

  group('인슐린 (MO-INSULIN-010/020/030)', () {
    test('이미 등록한 제품(409)은 중복 예외로 바꿈', () async {
      final (client, _) = _client((_) => _json(409, null, ok: false));
      await expectLater(
        ApiInsulinRepository(client).addMyInsulin(
          const InsulinProduct('란투스', InsulinCategory.longActing, id: '7'),
          10,
        ),
        throwsA(isA<DuplicateInsulinException>()),
      );
    });

    test('기록 저장 시 내 인슐린 id 와 투여량을 보냄', () async {
      final (client, requests) = _client(
        (_) => _json(200, {
          'insulinRecordId': 5,
          'memberInsulinId': 2,
          'name': '란투스',
          'actionType': 'LONG',
          'injectedAt': '2026-11-09T08:00:00',
          'doseUnit': 10.5,
          'memo': null,
        }),
      );
      final saved = await ApiInsulinRepository(client).saveRecord(
        InsulinRecord(
          time: DateTime(2026, 11, 9, 8),
          product: const InsulinProduct('란투스', InsulinCategory.longActing),
          dose: 10.5,
          memberInsulinId: '2',
        ),
      );
      expect(_body(requests.single), {
        'memberInsulinId': 2,
        'injectedAt': '2026-11-09T08:00:00',
        'doseUnit': 10.5,
        'memo': null,
      });
      expect(saved.product.category, InsulinCategory.longActing);
      expect(saved.memberInsulinId, '2');
    });
  });

  test('식단: 당류는 BE 필드명 sugarsG 로 읽음', () async {
    final (client, _) = _client(
      (_) => _json(200, {
        'foodId': 1,
        'name': '콜라',
        'servingAmount': 250,
        'servingUnit': 'ML',
        'nutrients': {'kcal': 108, 'sugarsG': 27},
      }),
    );
    final food = await ApiMealFoodRepository(client).detail(
      const MealFood(
        id: '1',
        name: '콜라',
        source: MealFoodSource.db,
        category: '가공 식품',
        servingGram: 250,
        servingUnit: 'ml',
        kcal: 108,
        carbs: 0,
        protein: 0,
        fat: 0,
      ),
    );
    expect(food.sugar, 27);
  });
}
