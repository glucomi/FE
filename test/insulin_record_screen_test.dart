import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/features/insulin/insulin_record_screen.dart';
import 'package:glucomi/features/insulin/insulin_register_screen.dart';
import 'package:glucomi/features/insulin/my_insulin_screen.dart';

void main() {
  final now = DateTime(2026, 4, 30, 14, 3);
  const levemir = InsulinProduct('레버미어플렉스펜주', InsulinCategory.longActing);

  /// 홈 → 인슐린 화면을 띄우고, 닫힐 때 돌려준 결과를 담아둠
  Future<List<InsulinRecordResult?>> open(
    WidgetTester tester,
    InsulinRepository repository, {
    InsulinRecord? record,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final results = <InsulinRecordResult?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                results.add(
                  await Navigator.of(context).push<InsulinRecordResult>(
                    MaterialPageRoute(
                      builder: (_) => InsulinRecordScreen(
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
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return results;
  }

  bool saveEnabled(WidgetTester tester) {
    final button = find.descendant(
      of: find.byKey(const ValueKey('insulin-save')),
      matching: find.byType(FilledButton),
    );
    return tester.widget<FilledButton>(button).onPressed != null;
  }

  testWidgets('(a) 오늘 날짜·현재 시간으로 진입, 인슐린 미선택이면 저장하기 비활성', (tester) async {
    await open(tester, SampleInsulinRepository());

    expect(find.text('2026년 04월 30일'), findsOneWidget);
    expect(find.text('오후 02:03'), findsOneWidget);
    expect(find.text('저장한 인슐린을 선택해주세요'), findsOneWidget);
    expect(find.text('투여량'), findsNothing);
    expect(find.text('0/1000'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('(b) 저장된 인슐린이 없으면 빈 상태 문구', (tester) async {
    await open(tester, SampleInsulinRepository());

    await tester.tap(find.byKey(const ValueKey('insulin-select')));
    await tester.pumpAndSettle();

    expect(find.text('0개'), findsOneWidget);
    expect(find.text('저장된 인슐린이 없습니다'), findsOneWidget);
    expect(find.text('새 인슐린을 추가해주세요'), findsOneWidget);
  });

  testWidgets('(c)→(d) 인슐린을 고르면 선택 완료 활성, 투여량을 불러와 저장', (tester) async {
    final repository = SampleInsulinRepository.withExamples();
    final results = await open(tester, repository);

    await tester.tap(find.byKey(const ValueKey('insulin-select')));
    await tester.pumpAndSettle();
    expect(find.text('3개'), findsOneWidget);

    final done = find.descendant(
      of: find.byKey(const ValueKey('insulin-select-done')),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(done).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('insulin-select-sample-2')));
    await tester.pump();
    expect(tester.widget<FilledButton>(done).onPressed, isNotNull);

    await tester.tap(done);
    await tester.pumpAndSettle();

    expect(find.text('레버미어플렉스펜주 (장기형)'), findsOneWidget);
    expect(find.text('투여량'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(saveEnabled(tester), isTrue);

    // 불러온 투여량도 고칠 수 있음
    await tester.enterText(find.byKey(const ValueKey('insulin-dose')), '2.5');
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    final saved = repository.records.single;
    expect(saved.product, levemir);
    expect(saved.dose, 2.5);
    expect(saved.time, DateTime(2026, 4, 30, 14, 3));
    expect(results.single?.record, saved);
  });

  testWidgets('투여량을 모두 지우면 저장하기 비활성', (tester) async {
    await open(tester, SampleInsulinRepository.withExamples());

    await tester.tap(find.byKey(const ValueKey('insulin-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('insulin-select-sample-1')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('insulin-select-done')));
    await tester.pumpAndSettle();
    expect(saveEnabled(tester), isTrue);

    await tester.enterText(find.byKey(const ValueKey('insulin-dose')), '');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);

    await tester.enterText(find.byKey(const ValueKey('insulin-dose')), '0');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);
  });

  testWidgets('닫기는 확인 팝업 없이 바로 닫히고 저장하지 않음', (tester) async {
    final repository = SampleInsulinRepository.withExamples();
    final results = await open(tester, repository);

    await tester.tap(find.byKey(const ValueKey('insulin-close')));
    await tester.pumpAndSettle();

    expect(find.byType(InsulinRecordScreen), findsNothing);
    expect(repository.records, isEmpty);
    expect(results.single, isNull);
  });

  testWidgets('내 인슐린 버튼 → MO-INSULIN-030', (tester) async {
    await open(tester, SampleInsulinRepository.withExamples());

    await tester.tap(find.byKey(const ValueKey('insulin-my-list')));
    await tester.pumpAndSettle();

    expect(find.byType(MyInsulinScreen), findsOneWidget);
    expect(find.text('노보래피드플렉스펜주'), findsOneWidget);
    expect(find.text('초속효성'), findsOneWidget);
  });

  testWidgets('바텀시트 새 인슐린 → MO-INSULIN-020', (tester) async {
    await open(tester, SampleInsulinRepository());

    await tester.tap(find.byKey(const ValueKey('insulin-select')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('insulin-select-add')));
    await tester.pumpAndSettle();

    expect(find.byType(InsulinRegisterScreen), findsOneWidget);
    expect(find.text('종류를 선택해주세요'), findsOneWidget);
  });

  testWidgets('(f) 등록후: 수정하기 → 바뀐 것 없이 저장하면 저장 호출 없이 복귀', (tester) async {
    final repository = SampleInsulinRepository();
    final record = InsulinRecord(
      id: 'r1',
      time: DateTime(2026, 4, 29, 9, 5),
      product: levemir,
      dose: 1,
    );
    final results = await open(tester, repository, record: record);

    expect(find.text('2026년 04월 29일'), findsOneWidget);
    expect(find.text('오전 09:05'), findsOneWidget);
    expect(find.text('삭제하기'), findsOneWidget);

    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();
    // 수정 모드에서도 저장된 시간을 그대로 유지
    expect(find.text('오전 09:05'), findsOneWidget);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(repository.records, isEmpty);
    expect(find.byType(InsulinRecordScreen), findsNothing);
    // 진입 화면(open 버튼이 있는 화면)까지만 닫힘
    expect(find.text('open'), findsOneWidget);
    expect(results, [null]);
  });

  testWidgets('(f) 수정 모드에서 인슐린 선택을 열면 저장된 제품이 선택돼 있음', (tester) async {
    final repository = SampleInsulinRepository.withExamples();
    final record = InsulinRecord(
      id: 'r1',
      time: DateTime(2026, 4, 29, 9, 5),
      product: levemir,
      dose: 1,
    );
    await open(tester, repository, record: record);

    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('insulin-select')));
    await tester.pumpAndSettle();

    final done = find.descendant(
      of: find.byKey(const ValueKey('insulin-select-done')),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(done).onPressed, isNotNull);
  });

  testWidgets('(f) 등록후: 삭제하기 → COM-POP-05 → 삭제', (tester) async {
    final repository = SampleInsulinRepository();
    final record = await repository.saveRecord(
      InsulinRecord(time: now, product: levemir, dose: 1),
    );
    final results = await open(tester, repository, record: record);

    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();

    expect(repository.records, isEmpty);
    expect(results.single?.deleted, isTrue);
  });

  group('MO-INSULIN-020 / 030', () {
    Future<void> pump(WidgetTester tester, Widget screen) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: screen));
      await tester.pumpAndSettle();
    }

    testWidgets('종류 선택 + 투여량 입력 시 등록, 같은 종류는 등록 안 함', (tester) async {
      final repository = SampleInsulinRepository.withExamples();
      await pump(tester, MyInsulinScreen(repository: repository));
      expect(find.text('레버미어플렉스펜주'), findsOneWidget);

      await tester.tap(find.text('새 인슐린 추가하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('insulin-register-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('insulin-type-휴마로그주')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('insulin-type-done')));
      await tester.pumpAndSettle();
      expect(find.text('휴마로그주 (초속효성)'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('insulin-register-dose')),
        '4',
      );
      await tester.pump();
      await tester.tap(find.text('등록하기'));
      await tester.pumpAndSettle();

      // 030 목록에 바로 반영
      expect(find.byType(InsulinRegisterScreen), findsNothing);
      expect(find.text('휴마로그주'), findsOneWidget);
      expect((await repository.myInsulins()).length, 4);

      // 같은 종류 다시 등록 → 안내 후 등록 안 함
      await tester.tap(find.text('새 인슐린 추가하기'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('insulin-register-type')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('insulin-type-휴마로그주')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('insulin-type-done')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('insulin-register-dose')),
        '2',
      );
      await tester.pump();
      await tester.tap(find.text('등록하기'));
      await tester.pumpAndSettle();

      expect(find.text('이미 등록된 인슐린이에요'), findsOneWidget);
      expect(find.byType(InsulinRegisterScreen), findsOneWidget);
      expect((await repository.myInsulins()).length, 4);
    });

    testWidgets('내 인슐린 X → 삭제 확인 → 모두 지우면 빈 상태', (tester) async {
      final repository = SampleInsulinRepository(
        myInsulins: const [MyInsulin(id: 'm1', product: levemir, dose: 1)],
      );
      await pump(tester, MyInsulinScreen(repository: repository));

      // {제품명} / {분류} | {투여량}
      expect(find.text('레버미어플렉스펜주'), findsOneWidget);
      expect(find.text('장기형 | 1U'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('my-insulin-m1')),
          matching: find.bySemanticsLabel('레버미어플렉스펜주 삭제'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('confirm-delete')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('my-insulin-empty')), findsOneWidget);
      expect(await repository.myInsulins(), isEmpty);
    });
  });
}
