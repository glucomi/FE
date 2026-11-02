import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';

void main() {
  Future<BuildContext> mount(WidgetTester tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              ctx = context;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    return ctx;
  }

  testWidgets('토스트는 문구를 보여주고 새 토스트가 오면 이전 것을 바로 내림',
      (tester) async {
    final context = await mount(tester);

    showAppToast(context, '첫 번째', type: AppToastType.success);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('app-toast')), findsOneWidget);
    expect(find.text('첫 번째'), findsOneWidget);

    showAppToast(context, '두 번째', type: AppToastType.error);
    await tester.pumpAndSettle();
    expect(find.text('첫 번째'), findsNothing);
    expect(find.text('두 번째'), findsOneWidget);
  });

  testWidgets('액션 버튼을 누르면 콜백 실행 후 토스트가 닫힘', (tester) async {
    final context = await mount(tester);
    var retried = 0;

    showAppToast(
      context,
      '저장하지 못했어요.',
      type: AppToastType.error,
      actionLabel: 'Retry',
      onAction: () => retried++,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(retried, 1);
    expect(find.text('저장하지 못했어요.'), findsNothing);
  });

  testWidgets('오버레이 토스트는 시간이 지나면 사라짐', (tester) async {
    final context = await mount(tester);

    showAppToastOverlay(context, '미래 날짜는 선택 불가합니다');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('미래 날짜는 선택 불가합니다'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('미래 날짜는 선택 불가합니다'), findsNothing);
  });
}
