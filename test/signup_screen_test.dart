import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/shared/widgets/app_icons.dart';
import 'package:flutter/gestures.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/signup/signup_screen.dart';
import 'package:glucomi/features/signup/term_document_screen.dart';
import 'package:glucomi/shared/widgets/app_checkbox.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    Future<void> Function(SignupConsent)? submit,
    void Function(SignupTerm)? detail,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: SignupScreen(onSubmit: submit, onOpenTerm: detail),
      ),
    );

    await tester.pumpAndSettle();
  }

  Future<void> toggle(WidgetTester tester, int index) async {
    await tester.tap(find.byKey(ValueKey('consent-$index')));
    await tester.pump();
  }

  FilledButton button(WidgetTester tester) {
    return tester.widget<FilledButton>(find.byType(FilledButton));
  }

  testWidgets('필수 약관 3개 동의 시 다음 버튼이 활성화된다', (tester) async {
    SignupConsent? sent;

    await mount(
      tester,
      submit: (value) async {
        sent = value;
      },
    );

    expect(button(tester).onPressed, isNull);

    for (var i = 0; i < 3; i++) {
      await toggle(tester, i);
    }

    expect(button(tester).onPressed, isNotNull);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(sent?.age, isTrue);
    expect(sent?.terms, isTrue);
    expect(sent?.privacy, isTrue);
  });

  testWidgets('전체 동의는 모든 항목을 함께 변경한다', (tester) async {
    await mount(tester);

    await tester.tap(find.byKey(const ValueKey('consent-all')));
    await tester.pump();

    final boxes = tester
        .widgetList<AppCheckbox>(find.byType(AppCheckbox))
        .toList();
    expect(boxes.length, 6);
    expect(boxes.every((item) => item.value), isTrue);
    await tester.tap(find.byType(AppCheckbox).first);
    await tester.pump();
    expect(
      tester
          .widgetList<AppCheckbox>(find.byType(AppCheckbox))
          .every((item) => !item.value),
      isTrue,
    );
  });

  testWidgets('약관 상세 버튼은 체크 상태와 독립적으로 동작한다', (tester) async {
    SignupTerm? opened;

    await mount(
      tester,
      detail: (value) {
        opened = value;
      },
    );

    await tester.tap(find.byKey(const ValueKey('term-2')));
    await tester.pump();

    expect(opened, SignupTerm.privacy);
    expect(button(tester).onPressed, isNull);
  });

  testWidgets('PDF가 없으면 빈 문서 화면을 표시한다', (tester) async {
    await mount(tester);

    await tester.tap(find.byKey(const ValueKey('term-1')));
    await tester.pumpAndSettle();

    expect(find.byType(TermDocumentScreen), findsOneWidget);
    expect(find.text('이용약관'), findsOneWidget);
    expect(find.byKey(const ValueKey('term-document-blank')), findsOneWidget);
  });

  testWidgets('중복 제출을 막고 실패 후 다시 시도할 수 있다', (tester) async {
    final pending = Completer<void>();
    var calls = 0;

    await mount(
      tester,
      submit: (_) {
        calls++;
        return pending.future;
      },
    );

    await tester.tap(find.byKey(const ValueKey('consent-all')));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(button(tester).onPressed, isNull);
    expect(calls, 1);

    pending.completeError(Exception('offline'));
    await tester.pumpAndSettle();

    expect(button(tester).onPressed, isNotNull);
    expect(find.text('가입을 완료하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
  });
  testWidgets('Figma 박스와 배경 없는 체크 및 행 hover', (tester) async {
    await mount(tester);
    expect(find.byType(AppChevronLeft), findsOneWidget);
    final boxes = find.byType(AppCheckbox);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    for (var i = 0; i < 6; i++) {
      final box = boxes.at(i);
      expect(tester.getSize(box), Size.square(i == 0 ? 20 : 24));
      BoxDecoration decoration() =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: box,
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      final row = find.byKey(
        ValueKey(i == 0 ? 'consent-all' : 'consent-${i - 1}'),
      );
      await mouse.moveTo(tester.getCenter(row));
      await tester.pump();
      if (i == 0) {
        expect(
          (decoration().border! as Border).top.color,
          AppColors.accentsBrand,
        );
        expect((decoration().border! as Border).top.width, 1.5);
      } else {
        expect(decoration().border, isNull);
        expect(decoration().color, Colors.transparent);
        expect(
          tester
              .widget<SvgPicture>(
                find.descendant(of: box, matching: find.byType(SvgPicture)),
              )
              .colorFilter,
          const ColorFilter.mode(AppColors.accentsBrand, BlendMode.srcIn),
        );
      }
      await mouse.moveTo(Offset.zero);
      await tester.pump();
      if (i == 0) {
        expect(
          (decoration().border! as Border).top.color,
          AppColors.borderStrong,
        );
      } else {
        expect(
          tester
              .widget<SvgPicture>(
                find.descendant(of: box, matching: find.byType(SvgPicture)),
              )
              .colorFilter,
          const ColorFilter.mode(AppColors.borderStrong, BlendMode.srcIn),
        );
      }
    }
    await tester.tap(boxes.at(1));
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(tester.widget<AppCheckbox>(boxes.at(1)).value, isTrue);
    expect(tester.widget<AppCheckbox>(boxes.first).value, isFalse);
    expect(
      tester
          .widget<SvgPicture>(
            find.descendant(of: boxes.at(1), matching: find.byType(SvgPicture)),
          )
          .colorFilter,
      const ColorFilter.mode(AppColors.accentsBrand, BlendMode.srcIn),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('제출 중에는 체크박스를 비활성화하고 hover를 무시한다', (tester) async {
    final pending = Completer<void>();
    await mount(tester, submit: (_) => pending.future);
    await tester.tap(find.byKey(const ValueKey('consent-all')));
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    for (final box in tester.widgetList<AppCheckbox>(
      find.byType(AppCheckbox),
    )) {
      expect(box.onChanged, isNull);
    }
    final opacity = find.descendant(
      of: find.byType(AppCheckbox).first,
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(opacity).opacity, 0.5);
    await tester.tap(find.byType(AppCheckbox).at(1));
    await tester.pump();
    expect(
      tester.widget<AppCheckbox>(find.byType(AppCheckbox).at(1)).value,
      isTrue,
    );
    pending.complete();
    await tester.pumpAndSettle();
  });
}
