import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/home/home_screen.dart';
import 'package:glucomi/features/home/widgets/calendar_day.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';

void main() {
  Future<void> mount(WidgetTester tester, HomeData data) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: HomeScreen(data: data)));
    await tester.pump();
  }

  testWidgets('센서 미연결 상태는 연결하기 버튼과 빈 기록 안내를 보여줌', (tester) async {
    await mount(tester, HomeData.empty(targetMin: 70, targetMax: 180));

    expect(find.text('연결 필요'), findsOneWidget);
    expect(find.text('연결하기'), findsOneWidget);
    expect(find.text('70-180mg/dl'), findsOneWidget);
    expect(find.text('기록이 없습니다'), findsNWidgets(2));
  });

  testWidgets('데이터가 있으면 오늘 혈당 범위와 요약 수치를 계산해 보여줌', (tester) async {
    final data = HomeData.sample(today: DateTime(2026, 9, 24));
    await mount(tester, data);

    expect(find.text('1일차'), findsOneWidget);
    expect(find.text('76'), findsOneWidget);
    expect(find.text('175'), findsWidgets);
    expect(find.text('새로고침'), findsOneWidget);
    expect(data.spikeCount, 2);
    expect(data.carbsGram, 20);
  });

  testWidgets('+ 버튼을 누르면 기록 메뉴가 열리고, 고르면 준비 중 안내', (tester) async {
    await mount(tester, HomeData.empty());

    await tester.tap(find.byKey(const ValueKey('home-add-record')));
    await tester.pumpAndSettle();

    for (final label in ['식단', '체중', '혈당', '인슐린', '복약', '운동', '메모']) {
      expect(find.text(label), findsOneWidget);
    }

    await tester.tap(find.text('식단'));
    await tester.pumpAndSettle();

    expect(find.text('식단'), findsNothing);
    expect(find.text('식단 기록 준비 중입니다.'), findsOneWidget);
  });

  testWidgets('음식 데이터가 있으면 식단을 눌러 음식 기록하기로 이동', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          data: HomeData.empty(),
          mealRepository: SampleMealFoodRepository(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home-add-record')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('식단'));
    await tester.pumpAndSettle();

    expect(find.text('음식 기록하기'), findsOneWidget);
  });

  testWidgets('기록 메뉴는 닫기 버튼으로 닫힘', (tester) async {
    await mount(tester, HomeData.empty());

    await tester.tap(find.byKey(const ValueKey('home-add-record')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('home-add-record-close')));
    await tester.pumpAndSettle();

    expect(find.text('인슐린'), findsNothing);
  });

  testWidgets('전체보기를 누르면 월 달력이 열리고 날짜를 고르면 닫힘', (tester) async {
    final data = HomeData.sample(today: DateTime(2026, 9, 24));
    await mount(tester, data);

    await tester.tap(find.text('전체보기'));
    await tester.pumpAndSettle();

    expect(find.text('2026.09'), findsOneWidget);
    expect(find.text('일'), findsOneWidget);

    // 미래 날짜는 선택되지 않음
    await tester.tap(find.byKey(const ValueKey('month-calendar-9-28')));
    await tester.pumpAndSettle();
    expect(find.text('2026.09'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('month-calendar-9-10')));
    await tester.pumpAndSettle();

    expect(find.text('2026.09'), findsNothing);
    expect(find.text('9월 10일 기록 보기 준비 중입니다.'), findsOneWidget);
  });

  test('달력 점수 구간', () {
    expect(CalendarMarkState.fromScore(null), CalendarMarkState.none);
    expect(CalendarMarkState.fromScore(84), CalendarMarkState.good);
    expect(CalendarMarkState.fromScore(56), CalendarMarkState.warning);
    expect(CalendarMarkState.fromScore(45), CalendarMarkState.danger);
  });
}
