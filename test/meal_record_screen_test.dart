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
    await tester.pumpAndSettle();

    expect(find.text('흑미밥'), findsOneWidget);
    expect(find.text('김밥'), findsOneWidget);
    expect(find.text('찾고 계신 ‘밥’이 없으신가요?'), findsOneWidget);
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

    // 흑미밥 150g 122kcal
    await tester.tap(find.byKey(const ValueKey('meal-food-black-rice')));
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

    await tester.tap(find.byKey(const ValueKey('meal-submit')));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.entries.single.food.name, '흑미밥');
    expect(result!.entries.single.grams, 160);
    expect(result!.title, '흑미밥');
    expect(result!.time, DateTime(2026, 9, 27, 12, 30));
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
