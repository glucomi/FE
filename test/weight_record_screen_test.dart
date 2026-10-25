import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/weight/weight_models.dart';
import 'package:glucomi/features/weight/weight_record_screen.dart';

class _FakeWeightRepository implements WeightRepository {
  WeightRecord? last;
  final saved = <WeightRecord>[];
  final deleted = <DateTime>[];

  @override
  Future<WeightRecord?> latest() async => last;

  @override
  Future<void> save(WeightRecord record) async => saved.add(record);

  @override
  Future<void> delete(DateTime date) async => deleted.add(date);
}

void main() {
  final today = DateTime(2026, 4, 30);

  /// 홈 → 체중 화면을 띄우고, 닫힐 때 돌려준 결과를 담아둠
  Future<List<WeightRecordResult?>> open(
    WidgetTester tester,
    WeightRepository repository, {
    WeightRecord? record,
    double? previousKg,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final results = <WeightRecordResult?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await Navigator.of(context).push<WeightRecordResult>(
                  MaterialPageRoute(
                    builder: (_) => WeightRecordScreen(
                      repository: repository,
                      record: record,
                      previousKg: previousKg,
                      today: today,
                    ),
                  ),
                ),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  testWidgets('(a) 직전 저장값이 없으면 기본 시작값, 오늘 날짜로 진입', (tester) async {
    await open(tester, _FakeWeightRepository());

    expect(find.text('60.0'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('2026년 04월 30일'), findsOneWidget);
    expect(find.text('저장하기'), findsOneWidget);
    expect(find.text('삭제하기'), findsNothing);
  });

  testWidgets('(a) 직전 저장값으로 진입하고 저장하면 해당 일자로 저장 후 복귀', (tester) async {
    final repository = _FakeWeightRepository()
      ..last = WeightRecord(date: DateTime(2026, 4, 1), kg: 47.7);
    final results = await open(tester, repository);

    expect(find.text('47.7'), findsOneWidget);
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(repository.saved.single, WeightRecord(date: today, kg: 47.7));
    expect(results.single?.record, WeightRecord(date: today, kg: 47.7));
    expect(find.byType(WeightRecordScreen), findsNothing);
  });

  testWidgets('(a) 날짜를 누르면 COM-POP-04, 선택 완료 시 반영', (tester) async {
    await open(tester, _FakeWeightRepository(), previousKg: 52.3);

    await tester.tap(find.byKey(const ValueKey('weight-date')));
    await tester.pumpAndSettle();
    expect(find.text('2026.04'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('weight-date-4-17')));
    await tester.tap(find.byKey(const ValueKey('weight-date-done')));
    await tester.pumpAndSettle();

    expect(find.text('2026.04'), findsNothing);
    expect(find.text('2026년 04월 17일'), findsOneWidget);
  });

  testWidgets('닫기는 확인 팝업 없이 바로 닫히고 저장하지 않음', (tester) async {
    final repository = _FakeWeightRepository();
    final results = await open(tester, repository);

    await tester.tap(find.byKey(const ValueKey('weight-close')));
    await tester.pumpAndSettle();

    expect(find.byType(WeightRecordScreen), findsNothing);
    expect(repository.saved, isEmpty);
    expect(results.single, isNull);
  });

  testWidgets('(b) 등록후: 수정하기 → 수치 변화 없이 저장하면 저장 호출 없이 홈 복귀', (tester) async {
    final repository = _FakeWeightRepository();
    await open(tester, repository, record: WeightRecord(date: today, kg: 52.3));

    expect(find.text('삭제하기'), findsOneWidget);
    expect(find.text('수정하기'), findsOneWidget);

    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();
    expect(find.text('저장하기'), findsOneWidget);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(repository.saved, isEmpty);
    expect(find.byType(WeightRecordScreen), findsNothing);
  });

  testWidgets('(b) 등록후: 삭제하기 → COM-POP-05 → 삭제', (tester) async {
    final repository = _FakeWeightRepository();
    final results = await open(
      tester,
      repository,
      record: WeightRecord(date: today, kg: 52.3),
    );

    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();
    expect(find.text('정말 삭제하시겠습니까?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();

    expect(repository.deleted.single, today);
    expect(results.single?.deleted, isTrue);
  });

  testWidgets('(b) 등록후: 삭제 팝업에서 취소하면 그대로', (tester) async {
    final repository = _FakeWeightRepository();
    await open(tester, repository, record: WeightRecord(date: today, kg: 52.3));

    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-cancel')));
    await tester.pumpAndSettle();

    expect(repository.deleted, isEmpty);
    expect(find.byType(WeightRecordScreen), findsOneWidget);
  });

  test('0~200kg, 0.1kg 단위로 맞춤', () {
    expect(WeightPolicy.normalize(250), 200);
    expect(WeightPolicy.normalize(-3), 0);
    expect(WeightPolicy.normalize(47.66), 47.7);
  });
}
