import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/drug/drug_models.dart';
import 'package:glucomi/features/drug/drug_record_screen.dart';

void main() {
  final now = DateTime(2026, 4, 30, 14, 3);

  Future<List<DrugRecordResult?>> open(
    WidgetTester tester,
    DrugRepository repository, {
    DrugRecord? record,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final results = <DrugRecordResult?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await Navigator.of(context).push<DrugRecordResult>(
                  MaterialPageRoute(
                    builder: (_) => DrugRecordScreen(
                      repository: repository,
                      record: record,
                      now: now,
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

  FilledButton saveButton(WidgetTester tester) => tester.widget<FilledButton>(
    find.descendant(
      of: find.byKey(const ValueKey('drug-save')),
      matching: find.byType(FilledButton),
    ),
  );

  testWidgets('(a) 오늘 날짜·현재 시간으로 진입, 복용약 미선택이면 저장 비활성', (tester) async {
    await open(tester, SampleDrugRepository());

    expect(find.text('2026년 04월 30일'), findsOneWidget);
    expect(find.text('오후 02:03'), findsOneWidget);
    expect(find.text('약 종류를 선택해주세요'), findsOneWidget);
    expect(find.text('제품명을 입력해주세요(선택)'), findsNothing);
    expect(saveButton(tester).onPressed, isNull);
  });

  testWidgets('(b) 저장된 복용약이 없으면 안내 문구', (tester) async {
    await open(tester, SampleDrugRepository());

    await tester.tap(find.byKey(const ValueKey('drug-select')));
    await tester.pumpAndSettle();

    expect(find.text('저장된 복용약이 없습니다'), findsOneWidget);
    expect(find.text('0개'), findsOneWidget);
  });

  testWidgets('(c)→(d) 복용약을 고르면 반영되고 저장 후 결과를 돌려줌', (tester) async {
    final repository = SampleDrugRepository(
      initial: const [
        SavedDrug(id: 'a', type: DrugType.diabetes, productName: '자디앙'),
      ],
    );
    final results = await open(tester, repository);

    await tester.tap(find.byKey(const ValueKey('drug-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('saved-item-0')));
    await tester.pump();
    await tester.tap(find.text('선택 완료'));
    await tester.pumpAndSettle();

    expect(find.text('당뇨약'), findsOneWidget);
    expect(find.text('자디앙'), findsOneWidget);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    final saved = results.single!.record!;
    expect(saved.type, DrugType.diabetes);
    expect(saved.productName, '자디앙');
    expect(saved.time, now);
  });

  testWidgets('(e) 등록후: 삭제하기/수정하기, 수정하기 탭 시 저장하기로 전환', (tester) async {
    final record = DrugRecord(
      id: 'r1',
      time: DateTime(2026, 4, 30, 8, 30),
      type: DrugType.supplement,
      productName: '오메가3',
    );
    await open(tester, SampleDrugRepository(), record: record);

    expect(find.text('오전 08:30'), findsOneWidget);
    expect(find.text('삭제하기'), findsOneWidget);
    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();

    expect(find.text('저장하기'), findsOneWidget);
    // 수정 모드에서도 저장된 시간 유지
    expect(find.text('오전 08:30'), findsOneWidget);
  });
}
