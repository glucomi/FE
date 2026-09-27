import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/home/home_screen.dart';

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

  testWidgets('기록 추가 버튼을 누르면 준비 중 안내', (tester) async {
    await mount(tester, HomeData.empty());

    await tester.tap(find.byKey(const ValueKey('home-add-record')));
    await tester.pump();

    expect(find.text('기록 추가 준비 중입니다.'), findsOneWidget);
  });
}
