import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/camera/food_analysis.dart';
import 'package:glucomi/features/glycemic/glycemic_screen.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/splash/splash_screen.dart';

void main() {
  testWidgets('MO-SPLASH-010 은 2000ms 뒤 다음 화면으로 넘어감', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(next: Text('다음 화면'))),
    );
    expect(find.byKey(const ValueKey('splash')), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1999));
    expect(find.text('다음 화면'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('다음 화면'), findsOneWidget);
  });

  test('AI 분석 응답 — 픽셀 center 를 사진 비율로 바꿈 (Python 출력 형식도 읽음)', () {
    final result = parseFoodAnalysis({
      'imageWidth': 400,
      'imageHeight': 200,
      'foods': [
        {'food_name': '김치찌개', 'confidence': 0.8, 'center': [100, 50]},
        {'foodName': '', 'confidence': 0.9},
      ],
    });
    expect(result.foods, hasLength(1));
    expect(result.foods.single.name, '김치찌개');
    expect(result.foods.single.center, const Offset(0.25, 0.25));
  });

  test('혈당 반응 — 식전·식후 최고·2시간 후 / 남은 시간', () {
    final meal = DateTime(2026, 4, 30, 14);
    final points = [
      CgmPoint(time: DateTime(2026, 4, 30, 13, 50), value: 100),
      CgmPoint(time: DateTime(2026, 4, 30, 14, 40), value: 180),
      CgmPoint(time: DateTime(2026, 4, 30, 16, 5), value: 120),
    ];
    final later = DateTime(2026, 4, 30, 17);

    expect(GlycemicPolicy.before(points, meal), 100);
    expect(GlycemicPolicy.peak(points, meal, later), 180);
    expect(GlycemicPolicy.after2h(points, meal, later), 120);
    expect(GlycemicPolicy.after2h(points, meal, DateTime(2026, 4, 30, 15)), isNull);
    expect(
      GlycemicPolicy.remaining(meal, DateTime(2026, 4, 30, 14, 28)),
      '1시간 32분',
    );
    expect(GlycemicPolicy.remaining(meal, later), isNull);
  });
}
