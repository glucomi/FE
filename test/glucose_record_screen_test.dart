import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/glucose_record/glucose_record_models.dart';
import 'package:glucomi/features/glucose_record/glucose_record_screen.dart';

class _FakeGlucoseRepository implements GlucoseRecordRepository {
  final saved = <GlucoseRecord>[];
  final deleted = <String>[];

  @override
  Future<GlucoseRecord> save(GlucoseRecord record) async {
    final result = record.id == null ? record.copyWith(id: 'new') : record;
    saved.add(result);
    return result;
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

void main() {
  final today = DateTime(2026, 4, 30);
  final now = DateTime(2026, 4, 30, 14, 3);
  final existing = GlucoseRecord(
    id: 'g1',
    time: DateTime(2026, 4, 30, 9, 5),
    mgDl: 124,
  );

  Finder saveButton() => find.widgetWithText(FilledButton, '저장하기');

  bool saveEnabled(WidgetTester tester) =>
      tester.widget<FilledButton>(saveButton()).onPressed != null;

  /// 홈 → 혈당 화면을 띄우고, 닫힐 때 돌려준 결과를 담아둠
  Future<List<GlucoseRecordResult?>> open(
    WidgetTester tester,
    GlucoseRecordRepository repository, {
    GlucoseRecord? record,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final results = <GlucoseRecordResult?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await Navigator.of(context).push<GlucoseRecordResult>(
                  MaterialPageRoute(
                    builder: (_) => GlucoseRecordScreen(
                      repository: repository,
                      record: record,
                      today: today,
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

  testWidgets('(a) 오늘 날짜·현재 시각으로 진입, 값이 없으면 저장하기 비활성', (tester) async {
    await open(tester, _FakeGlucoseRepository());

    expect(find.text('2026년 04월 30일'), findsOneWidget);
    expect(find.text('오후 02:03'), findsOneWidget);
    expect(find.text('혈당값을 입력해주세요'), findsOneWidget);
    expect(find.text('0/1000'), findsOneWidget);
    expect(saveEnabled(tester), isFalse);
    expect(find.text('삭제하기'), findsNothing);
  });

  testWidgets('(a) 혈당값·메모 입력 후 저장하면 저장 후 복귀', (tester) async {
    final repository = _FakeGlucoseRepository();
    final results = await open(tester, repository);

    await tester.enterText(find.byKey(const ValueKey('glucose-value')), '124');
    await tester.enterText(
      find.byKey(const ValueKey('glucose-memo')),
      '식후 2시간',
    );
    await tester.pump();
    expect(find.text('6/1000'), findsOneWidget);
    expect(saveEnabled(tester), isTrue);

    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    final saved = repository.saved.single;
    expect(saved.mgDl, 124);
    expect(saved.memo, '식후 2시간');
    expect(saved.time, now);
    expect(results.single?.record, saved);
    expect(find.byType(GlucoseRecordScreen), findsNothing);
  });

  testWidgets('범위 미만 값은 저장하기 비활성', (tester) async {
    await open(tester, _FakeGlucoseRepository());

    await tester.enterText(find.byKey(const ValueKey('glucose-value')), '9');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);

    await tester.enterText(find.byKey(const ValueKey('glucose-value')), '10');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('범위 초과 수치를 입력한 뒤 키보드를 닫으면 초기화·안내', (tester) async {
    await open(tester, _FakeGlucoseRepository());
    final input = find.byKey(const ValueKey('glucose-value'));
    await tester.enterText(input, '301');
    await tester.pump();
    expect(saveEnabled(tester), isFalse);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('301'), findsNothing);
    expect(find.text('혈당은 10~300 mg/dL 범위로 입력해주세요'), findsOneWidget);
    await tester.enterText(input, '300');
    await tester.pump();
    expect(saveEnabled(tester), isTrue);
  });

  testWidgets('시간을 누르면 COM-POP-03, 선택 완료 시 반영', (tester) async {
    await open(tester, _FakeGlucoseRepository());

    await tester.tap(find.byKey(const ValueKey('glucose-time')));
    await tester.pumpAndSettle();
    expect(find.text('선택 완료'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('app-time-done')));
    await tester.pumpAndSettle();
    expect(find.text('오후 02:03'), findsOneWidget);
  });

  testWidgets('닫기는 확인 팝업 없이 바로 닫히고 저장하지 않음', (tester) async {
    final repository = _FakeGlucoseRepository();
    final results = await open(tester, repository);

    await tester.enterText(find.byKey(const ValueKey('glucose-value')), '150');
    await tester.tap(find.byKey(const ValueKey('glucose-close')));
    await tester.pumpAndSettle();

    expect(find.byType(GlucoseRecordScreen), findsNothing);
    expect(repository.saved, isEmpty);
    expect(results.single, isNull);
  });

  testWidgets('(c) 등록후: 저장된 값으로 보이고 수정 불가, 삭제하기/수정하기 노출', (tester) async {
    await open(tester, _FakeGlucoseRepository(), record: existing);

    expect(find.text('124'), findsOneWidget);
    expect(find.text('오전 09:05'), findsOneWidget);
    expect(find.text('삭제하기'), findsOneWidget);
    expect(find.text('수정하기'), findsOneWidget);

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('glucose-value')),
    );
    expect(field.readOnly, isTrue);

    // 날짜를 눌러도 시트가 뜨지 않음
    await tester.tap(find.byKey(const ValueKey('glucose-date')));
    await tester.pumpAndSettle();
    expect(find.text('선택 완료'), findsNothing);
  });

  testWidgets('(b) 수정하기 → 변화 없이 저장하면 저장 호출 없이 홈 복귀', (tester) async {
    final repository = _FakeGlucoseRepository();
    await open(tester, repository, record: existing);

    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();
    expect(saveButton(), findsOneWidget);
    // 수정 모드에서도 저장된 시간 유지
    expect(find.text('오전 09:05'), findsOneWidget);

    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(repository.saved, isEmpty);
    expect(find.byType(GlucoseRecordScreen), findsNothing);
  });

  testWidgets('(b) 수정하기 → 값 변경 후 저장하면 같은 id 로 수정', (tester) async {
    final repository = _FakeGlucoseRepository();
    final results = await open(tester, repository, record: existing);

    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('glucose-value')), '98');
    await tester.pump();
    await tester.tap(saveButton());
    await tester.pumpAndSettle();

    expect(repository.saved.single.id, 'g1');
    expect(repository.saved.single.mgDl, 98);
    expect(repository.saved.single.time, existing.time);
    expect(results.single?.record?.mgDl, 98);
  });

  testWidgets('(c) 삭제하기 → COM-POP-05 → 삭제', (tester) async {
    final repository = _FakeGlucoseRepository();
    final results = await open(tester, repository, record: existing);

    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();
    expect(find.text('정말 삭제하시겠습니까?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();

    expect(repository.deleted.single, 'g1');
    expect(results.single?.deleted, isTrue);
  });

  group('GlucoseValueInputFormatter', () {
    const formatter = GlucoseValueInputFormatter();

    TextEditingValue apply(String oldText, String newText) =>
        formatter.formatEditUpdate(
          TextEditingValue(text: oldText),
          TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          ),
        );

    test('선행 0 정리', () {
      expect(apply('', '0').text, '');
      expect(apply('0', '012').text, '12');
    });

    test('범위 밖 3자리 입력은 허용, 4자리는 차단', () {
      expect(apply('30', '301').text, '301');
      expect(apply('300', '3000').text, '300');
      expect(apply('29', '299').text, '299');
    });

    test('숫자 외 문자 제거', () {
      expect(apply('12', '12.').text, '12');
    });
  });
}
