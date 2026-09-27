import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/camera/food_camera_screen.dart';

void main() {
  testWidgets('카메라를 못 쓰면 안내하고, 촬영 안내 문구와 앨범 버튼을 보여줌', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // 테스트 환경에는 카메라 플러그인이 없어서 사용할 수 없는 상태가 됨
    await tester.pumpWidget(const MaterialApp(home: FoodCameraScreen()));
    await tester.pumpAndSettle();

    expect(find.text('정확한 분석을 위해'), findsOneWidget);
    expect(find.text('식단 전체가 포함되도록 촬영해주세요'), findsOneWidget);
    expect(find.textContaining('앨범에서 사진을 선택해 주세요'), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-gallery')), findsOneWidget);
    expect(find.byKey(const ValueKey('camera-shutter')), findsOneWidget);
  });

  testWidgets('닫기를 누르면 이전 화면으로 돌아감', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FoodCameraScreen()),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('정확한 분석을 위해'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('camera-close')));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
