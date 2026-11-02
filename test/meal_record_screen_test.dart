import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/meal_record_screen.dart';

void main() {
  Future<void> setSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  Future<void> mount(WidgetTester tester, MealFoodRepository repo) async {
    await setSize(tester);
    await tester.pumpWidget(
      MaterialApp(home: MealRecordScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('탭마다 목록 또는 빈 안내를 보여줌', (tester) async {
    await mount(tester, SampleMealFoodRepository());

    expect(find.text('음식 기록하기'), findsOneWidget);
    expect(find.text('흑미밥'), findsOneWidget);
    expect(find.text('참치'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-tab-1')));
    await tester.pumpAndSettle();
    expect(find.text('김밥'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-tab-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('meal-register-button')), findsOneWidget);
  });

  testWidgets('기록이 없으면 탭별 빈 안내', (tester) async {
    await mount(tester, SampleMealFoodRepository.empty());

    expect(find.text('아직 즐겨찾기한 음식이 없어요'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-tab-2')));
    await tester.pumpAndSettle();
    expect(find.text('아직 직접 등록한 음식이 없어요'), findsOneWidget);
  });

  testWidgets('검색하면 결과와 직접 등록 안내, 지우면 탭으로 돌아감', (tester) async {
    await mount(tester, SampleMealFoodRepository());

    await tester.enterText(find.byKey(const ValueKey('meal-search-field')), '밥');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('흑미밥'), findsOneWidget);
    expect(find.text('김밥'), findsOneWidget);
    expect(find.text('찾고 계신 음식이 없으신가요?'), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-suggest-query')), findsOneWidget);
    // 검색 요령 안내는 목록 아래쪽에 있어서 스크롤해서 확인
    await tester.dragUntilVisible(
      find.text('이렇게 해보는건 어때요?'),
      find.byType(ListView),
      const Offset(0, -200),
    );
    expect(find.text('이렇게 해보는건 어때요?'), findsOneWidget);
    expect(find.text('즐겨찾기'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('meal-search-clear')));
    await tester.pumpAndSettle();
    expect(find.text('즐겨찾기'), findsOneWidget);
  });

  testWidgets('음식을 골라 양을 바꾸고 담은 뒤 기록하면 결과를 돌려줌', (tester) async {
    await setSize(tester);
    MealRecord? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<MealRecord>(
                MaterialPageRoute(
                  builder: (_) => MealRecordScreen(
                    repository: SampleMealFoodRepository(),
                    clock: () => DateTime(2026, 9, 27, 12, 30),
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

    // 흑미밥 150g 122kcal — 선택 버튼은 수량 입력 바텀시트
    await tester.tap(find.byKey(const ValueKey('meal-food-select-black-rice')));
    await tester.pumpAndSettle();
    expect(find.text('영양정보'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-amount-inc')));
    await tester.pump();
    expect(find.text('160'), findsOneWidget);
    expect(find.text('130kcal'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-add')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('meal-submit')), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    // 기록하기 → MO-MEAL-040 저장 화면
    await tester.tap(find.byKey(const ValueKey('meal-submit')));
    await tester.pumpAndSettle();
    expect(find.text('식사 메뉴'), findsOneWidget);
    expect(find.text('2026년 09월 27일'), findsOneWidget);
    expect(find.text('오후 12:30'), findsOneWidget);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.entries.single.food.name, '흑미밥');
    expect(result!.entries.single.grams, 160);
    expect(result!.title, '흑미밥');
    expect(result!.time, DateTime(2026, 9, 27, 12, 30));
  });

  testWidgets('음식명을 누르면 상세(030)에서 수량을 바꿔 담음', (tester) async {
    await mount(tester, SampleMealFoodRepository());

    await tester.tap(find.byKey(const ValueKey('meal-food-detail-black-rice')));
    await tester.pumpAndSettle();

    expect(find.text('예상 혈당 변화'), findsOneWidget);
    expect(find.byKey(const ValueKey('meal-glucose-grade')), findsOneWidget);
    expect(find.text('당류'), findsOneWidget);
    expect(find.text('기준량'), findsOneWidget);
    expect(find.text('트랜스지방'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-detail-amount-inc')));
    await tester.pump();
    expect(find.byKey(const ValueKey('meal-detail-kcal')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('meal-detail-kcal'))).data,
      '130',
    );

    // 단위는 탭할 때마다 순환 (g → 인분)
    await tester.tap(find.byKey(const ValueKey('meal-detail-unit-select')));
    await tester.pump();
    expect(find.text('인분'), findsOneWidget);

    await tester.tap(find.text('추가하기'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('meal-submit')), findsOneWidget);
  });

  testWidgets('저장 화면에서 메뉴를 모두 지우면 저장하기 비활성화', (tester) async {
    await mount(tester, SampleMealFoodRepository());

    await tester.tap(find.byKey(const ValueKey('meal-food-select-black-rice')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-submit')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('meal-save-remove-black-rice')));
    await tester.pumpAndSettle();
    expect(find.text('흑미밥'), findsNothing);

    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    // 그대로 저장 화면
    expect(find.text('식사 메뉴'), findsOneWidget);

    // 메모 글자 수
    await tester.enterText(find.byKey(const ValueKey('meal-save-memo')), '천천히');
    await tester.pump();
    expect(find.text('3/1000'), findsOneWidget);
  });

  testWidgets('직접 등록: 필수값을 채워야 저장되고 등록 후 바로 담김', (tester) async {
    await mount(tester, SampleMealFoodRepository());

    await tester.tap(find.byKey(const ValueKey('meal-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meal-register-button')));
    await tester.pumpAndSettle();
    expect(find.text('직접 등록'), findsWidgets);

    await tester.enterText(find.byKey(const ValueKey('meal-register-name')).last, '닭가슴살볼');
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();
    // 열량 미입력 → 저장 안 됨
    expect(find.text('브랜드명'), findsOneWidget);

    await tester.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('meal-register-kcal')),
        matching: find.byType(TextField),
      ),
      '120',
    );
    await tester.pump();
    await tester.tap(find.text('저장하기'));
    await tester.pumpAndSettle();

    // COM-POP-02 에 담김
    expect(find.byKey(const ValueKey('meal-submit')), findsOneWidget);
    expect(find.text('닭가슴살볼'), findsWidgets);
  });

  test('예상 혈당 등급과 조사', () {
    expect(GlucoseGrade.of(4), GlucoseGrade.aPlus);
    expect(GlucoseGrade.of(16), GlucoseGrade.bPlus);
    expect(GlucoseGrade.of(80), GlucoseGrade.f);
    expect(josa('밥', '이', '가'), '이');
    expect(josa('김치', '이', '가'), '가');
  });

  test('단위와 양에 따라 영양 정보를 계산', () {
    const food = MealFood(
      id: 'x',
      name: '테스트',
      servingGram: 200,
      kcal: 300,
      carbs: 40,
    );
    const half = MealEntry(food: food, amount: 100);
    const twoServings = MealEntry(food: food, amount: 2, unit: MealUnit.serving);

    expect(half.kcal, 150);
    expect(half.carbs, 20);
    expect(twoServings.grams, 400);
    expect(twoServings.kcal, 600);
    expect(formatMealNumber(1.5), '1.5');
    expect(formatMealNumber(150), '150');
  });
}
