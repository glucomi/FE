import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/curation/curation_models.dart';
import 'package:glucomi/features/curation/curation_screen.dart';
import 'package:glucomi/shared/widgets/app_icons.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    Future<void> Function(CurationResult)? onComplete,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: CurationScreen(onComplete: onComplete)),
    );
  }

  FilledButton nextButton(WidgetTester tester) =>
      tester.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('당뇨 유형을 고르기 전에는 다음 버튼이 비활성', (tester) async {
    await mount(tester);

    expect(find.text('STEP 01'), findsOneWidget);
    expect(nextButton(tester).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('diabetes-type2Insulin')));
    await tester.pump();

    expect(nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('4단계를 거쳐 완료하면 결과가 전달됨', (tester) async {
    CurationResult? result;
    await mount(tester, onComplete: (r) async => result = r);

    await tester.tap(find.byKey(const ValueKey('diabetes-gestational')));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('키를 입력해주세요'), findsOneWidget);
    expect(find.text('165'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('몸무게를 입력해주세요'), findsOneWidget);
    expect(find.text('60.0'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('목표 혈당 범위를 입력해주세요'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.diabetesType, DiabetesType.gestational);
    expect(result!.heightCm, 165);
    expect(result!.weightKg, 60.0);
    expect(result!.targetMin, 60);
    expect(result!.targetMax, 140);
  });

  testWidgets('2단계에서 뒤로가기를 누르면 1단계로 돌아감', (tester) async {
    await mount(tester);

    await tester.tap(find.byKey(const ValueKey('diabetes-type1')));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('STEP 02'), findsOneWidget);

    await tester.tap(find.byType(AppChevronLeft));
    await tester.pumpAndSettle();
    expect(find.text('STEP 01'), findsOneWidget);
  });
}
