import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/exercise/exercise_add_screen.dart';
import 'package:glucomi/features/exercise/exercise_models.dart';
import 'package:glucomi/features/exercise/exercise_record_screen.dart';

const _walk = Exercise(id: 'walk', name: '걷기', kcalPerBase: 65);
const _run = Exercise(id: 'run', name: '달리기', kcalPerBase: 240);

void main() {
  final now = DateTime(2026, 4, 30, 14, 3);

  Future<List<ExerciseRecordResult?>> open(
    WidgetTester tester,
    ExerciseRepository repository, {
    ExerciseRecord? record,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final results = <ExerciseRecordResult?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              results.add(
                await Navigator.of(context).push<ExerciseRecordResult>(
                  MaterialPageRoute(
                    builder: (_) => ExerciseRecordScreen(
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

  Future<void> addWalk(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('exercise-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('exercise-option-walk')).last);
    await tester.pump();
    await tester.tap(find.text('추가하기'));
    await tester.pumpAndSettle();
  }

  testWidgets('(a) 오늘 날짜·현재 시각으로 진입, 운동이 없으면 저장 안 됨', (tester) async {
    final repository = SampleExerciseRepository(exercises: [_walk, _run]);
    final results = await open(tester, repository);

    expect(find.text('2026년 04월 30일'), findsOneWidget);
    expect(find.text('오후 02:03'), findsOneWidget);
    expect(find.text('운동 추가하기'), findsOneWidget);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(results, isEmpty);
    expect(await repository.recent(), isEmpty);
  });

  testWidgets('운동 추가 → 기본 30분 · 칼로리 표시, 시간 바꾸면 칼로리 재계산', (tester) async {
    await open(tester, SampleExerciseRepository(exercises: [_walk, _run]));
    await addWalk(tester);

    expect(find.byType(ExerciseAddScreen), findsNothing);
    expect(find.text('걷기'), findsOneWidget);
    expect(find.text('30'), findsOneWidget);
    expect(find.text('65 kcal'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('exercise-entry-minutes')),
      '45',
    );
    await tester.pump();
    expect(find.text('98 kcal'), findsOneWidget);
  });

  testWidgets('0분/빈 값이면 저장 안 되고, 항목 삭제 시 (a) 로 복귀', (tester) async {
    final repository = SampleExerciseRepository(exercises: [_walk, _run]);
    final results = await open(tester, repository);
    await addWalk(tester);

    await tester.enterText(
      find.byKey(const ValueKey('exercise-entry-minutes')),
      '',
    );
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(results, isEmpty);

    await tester.tap(find.byKey(const ValueKey('exercise-entry-remove')));
    await tester.pump();
    expect(find.text('운동 추가하기'), findsOneWidget);
  });

  testWidgets('저장하면 기록을 돌려주고 최근 기록한 운동에 노출', (tester) async {
    final repository = SampleExerciseRepository(exercises: [_walk, _run]);
    final results = await open(tester, repository);
    await addWalk(tester);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    final saved = results.single!.record!;
    expect(saved.id, isNotNull);
    expect(saved.time, now);
    expect(saved.totalKcal, 65);
    expect(await repository.recent(), [_walk]);
  });

  testWidgets('020: 검색은 엔터로 실행, 결과 없으면 안내, 지우면 기본 목록', (tester) async {
    await open(tester, SampleExerciseRepository(exercises: [_walk, _run]));
    await tester.tap(find.byKey(const ValueKey('exercise-add')));
    await tester.pumpAndSettle();

    expect(find.text('최근 기록한 운동'), findsNothing);
    expect(find.text('운동 목록'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '얄리얄리');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('해당 운동을 찾지 못했어요'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '달');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('exercise-option-run')), findsOneWidget);
    expect(find.byKey(const ValueKey('exercise-option-walk')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('meal-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('운동 목록'), findsOneWidget);
  });

  testWidgets('(c) 등록후: 삭제하기 → 확인 시 삭제, 수정하기 → 변경 없으면 저장 없이 복귀', (
    tester,
  ) async {
    final repository = SampleExerciseRepository(exercises: [_walk, _run]);
    final record = await repository.save(
      ExerciseRecord(
        time: now,
        entries: const [ExerciseEntry(exercise: _walk, minutes: 45)],
      ),
    );
    await open(tester, repository, record: record);

    expect(find.text('삭제하기'), findsOneWidget);
    expect(find.text('45'), findsOneWidget);

    await tester.tap(find.text('수정하기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseRecordScreen), findsNothing);
    expect(await repository.recent(), [_walk]);
  });
}
