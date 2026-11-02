import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/memo/memo_models.dart';
import 'package:glucomi/features/memo/memo_record_screen.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

class _FakeMemoRepository implements MemoRepository {
  final saved = <MemoRecord>[];
  final deleted = <String>[];

  @override
  Future<MemoRecord> save(MemoRecord record) async {
    final result = record.id == null ? record.copyWith(id: 'm1') : record;
    saved.add(result);
    return result;
  }

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

/// 1x1 투명 PNG
final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

void main() {
  final now = DateTime(2026, 4, 30, 14, 3);

  /// 홈 → 메모 화면을 띄우고, 닫힐 때 돌려준 결과를 담아둠
  Future<List<MemoRecordResult?>> open(
    WidgetTester tester,
    MemoRepository repository, {
    MemoRecord? record,
    MemoPhotoPicker? pickPhoto,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final results = <MemoRecordResult?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await Navigator.of(context).push<MemoRecordResult>(
                  MaterialPageRoute(
                    builder: (_) => MemoRecordScreen(
                      repository: repository,
                      record: record,
                      now: now,
                      pickPhoto:
                          pickPhoto ?? (_) async => MemoPhoto(_png, name: 'a'),
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

  VoidCallback? saveAction(WidgetTester tester) => tester
      .widget<AppButton>(find.widgetWithText(AppButton, '저장하기'))
      .onPressed;

  testWidgets('(a) 오늘 날짜·현재 시간으로 진입하고, 입력 전에는 저장하기 비활성', (tester) async {
    await open(tester, _FakeMemoRepository());

    expect(find.text('메모'), findsWidgets);
    expect(find.text('2026년 04월 30일'), findsOneWidget);
    expect(find.text('오후 02:03'), findsOneWidget);
    expect(find.text('메모를 입력해주세요.'), findsOneWidget);
    expect(find.text('0/1000'), findsOneWidget);
    expect(find.text('삭제하기'), findsNothing);
    expect(saveAction(tester), isNull);
  });

  testWidgets('공백만 입력하면 비활성, 글자를 입력하면 저장 후 결과를 돌려줌', (tester) async {
    final repository = _FakeMemoRepository();
    final results = await open(tester, repository);

    await tester.enterText(find.byKey(const ValueKey('memo-text')), '   ');
    await tester.pump();
    expect(saveAction(tester), isNull);

    await tester.enterText(find.byKey(const ValueKey('memo-text')), ' 배고팠다 ');
    await tester.pump();
    expect(find.text('6/1000'), findsOneWidget);
    expect(saveAction(tester), isNotNull);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(repository.saved.single.text, '배고팠다');
    expect(repository.saved.single.time, now);
    expect(results.single?.record?.id, 'm1');
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('메모는 최대 1000자까지만 입력됨', (tester) async {
    await open(tester, _FakeMemoRepository());

    await tester.enterText(
      find.byKey(const ValueKey('memo-text')),
      'ㄱ' * 1005,
    );
    await tester.pump();

    expect(find.text('1000/1000'), findsOneWidget);
  });

  testWidgets('사진만 추가해도 저장 가능, 사진을 지우면 다시 비활성', (tester) async {
    final repository = _FakeMemoRepository();
    await open(tester, repository);

    await tester.tap(find.byKey(const ValueKey('memo-add-photo')));
    await tester.pumpAndSettle();

    expect(find.text('1/1'), findsOneWidget);
    expect(saveAction(tester), isNotNull);

    await tester.tap(find.byKey(const ValueKey('memo-photo-remove')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('memo-photo-pages')), findsNothing);
    expect(saveAction(tester), isNull);
  });

  testWidgets('사진 추가를 취소하면 그대로', (tester) async {
    await open(tester, _FakeMemoRepository(), pickPhoto: (_) async => null);

    await tester.tap(find.byKey(const ValueKey('memo-add-photo')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('memo-photo-pages')), findsNothing);
    expect(saveAction(tester), isNull);
  });

  testWidgets('닫기는 입력이 있어도 확인 팝업 없이 바로 닫힘', (tester) async {
    final repository = _FakeMemoRepository();
    final results = await open(tester, repository);

    await tester.enterText(find.byKey(const ValueKey('memo-text')), '저장 안 함');
    await tester.tap(find.byKey(const ValueKey('memo-close')));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
    expect(results, [null]);
    expect(repository.saved, isEmpty);
  });

  final registered = MemoRecord(
    id: 'memo-7',
    time: DateTime(2026, 4, 29, 9, 5),
    text: '배고팠다',
  );

  testWidgets('(c) 등록후: 읽기 전용, 삭제하기·수정하기 노출', (tester) async {
    await open(tester, _FakeMemoRepository(), record: registered);

    expect(find.text('2026년 04월 29일'), findsOneWidget);
    expect(find.text('오전 09:05'), findsOneWidget);
    expect(find.text('배고팠다'), findsOneWidget);
    expect(find.text('삭제하기'), findsOneWidget);
    expect(find.text('수정하기'), findsOneWidget);
    expect(find.text('저장하기'), findsNothing);

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('memo-text')),
    );
    expect(field.readOnly, isTrue);
  });

  testWidgets('(c) 수정하기 → 저장된 시간 유지, 변경 없이 저장하면 저장 호출 없이 복귀', (
    tester,
  ) async {
    final repository = _FakeMemoRepository();
    final results = await open(tester, repository, record: registered);

    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();

    expect(find.text('저장하기'), findsOneWidget);
    expect(find.text('오전 09:05'), findsOneWidget);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(repository.saved, isEmpty);
    expect(results, [null]);
  });

  testWidgets('(c) 수정 후 저장하면 같은 id 로 갱신', (tester) async {
    final repository = _FakeMemoRepository();
    final results = await open(tester, repository, record: registered);

    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('memo-text')), '배불렀다');
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(repository.saved.single.id, 'memo-7');
    expect(repository.saved.single.time, registered.time);
    expect(results.single?.record?.text, '배불렀다');
  });

  testWidgets('(c) 삭제하기 → COM-POP-05 → 삭제', (tester) async {
    final repository = _FakeMemoRepository();
    final results = await open(tester, repository, record: registered);

    await tester.tap(find.text('삭제하기'));
    await tester.pumpAndSettle();
    expect(find.text('정말 삭제하시겠습니까?'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('confirm-delete')));
    await tester.pumpAndSettle();

    expect(repository.deleted, ['memo-7']);
    expect(results.single?.deleted, isTrue);
  });
}
