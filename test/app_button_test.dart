import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/shared/widgets/app_button.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';

void main() {
  testWidgets('button renders Figma colors through pointer states', (
    tester,
  ) async {
    var calls = 0;
    Future<void> mount(bool enabled) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 328,
              child: AppButton(
                label: '다음',
                onPressed: enabled ? () => calls++ : null,
              ),
            ),
          ),
        ),
      ),
    );
    await mount(true);
    await tester.pumpAndSettle();
    final button = find.byType(FilledButton);
    Material material() => tester.widget<Material>(
      find.descendant(of: button, matching: find.byType(Material)).first,
    );
    expect(tester.getSize(button), const Size(328, 48));
    expect(material().color, const Color(0xFF00A18E));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    final center = tester.getCenter(button);
    await mouse.moveTo(center);
    await tester.pumpAndSettle();
    expect(material().color, const Color(0xFF008173));
    await mouse.down(center);
    await tester.pumpAndSettle();
    expect(material().color, const Color(0xFF006158));
    expect(calls, 0);
    await mouse.up();
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(material().color, const Color(0xFF008173));
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(material().color, const Color(0xFF00A18E));
    await mount(false);
    await tester.pumpAndSettle();
    await mouse.moveTo(center);
    await mouse.down(center);
    await mouse.up();
    await tester.pumpAndSettle();
    expect(material().color, const Color(0xFFCCF0EC));
    expect(calls, 1);
  });

  testWidgets('keyboard focus renders the three pixel Figma ring', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppButton(label: '다음', onPressed: () {}),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    final material = tester.widget<Material>(
      find
          .descendant(
            of: find.byType(FilledButton),
            matching: find.byType(Material),
          )
          .first,
    );
    final shape = material.shape! as RoundedRectangleBorder;
    expect(shape.side.width, 3);
    expect(shape.side.color, const Color(0xFF00A18E));
    expect(shape.side.strokeAlign, BorderSide.strokeAlignOutside);
    expect(shape.borderRadius, BorderRadius.circular(8));
  });

  testWidgets('header keeps height and paints the bottom divider', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppHeaderBar())),
    );
    expect(tester.getSize(find.byType(AppHeaderBar)).height, 56);
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AppHeaderBar),
            matching: find.byType(Container),
          )
          .first,
    );
    final border =
        (container.foregroundDecoration! as BoxDecoration).border! as Border;
    expect(border.bottom.color, const Color(0xFFF0F2F5));
    expect(border.bottom.width, 1);
  });
}
