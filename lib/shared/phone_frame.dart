import 'package:flutter/material.dart';

/// PC 브라우저처럼 화면이 넓으면 Figma 기준 360x800 폰 크기로 가운데 고정
/// (창이 작으면 비율 유지한 채 축소). 폰에서는 화면 전체 사용
class PhoneFrame extends StatelessWidget {
  const PhoneFrame({super.key, required this.child});

  final Widget? child;

  /// Figma 화면 크기
  static const Size designSize = Size(360, 800);

  /// 이보다 넓으면 PC 로 보고 폰 크기로 고정
  static const double phoneMaxWidth = 600;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    final screen = MediaQuery.sizeOf(context);
    if (screen.width <= phoneMaxWidth) return content;

    return ColoredBox(
      color: const Color(0xFFF5F6F8),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox.fromSize(
            size: designSize,
            child: ClipRect(
              child: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: designSize,
                  padding: EdgeInsets.zero,
                  viewPadding: EdgeInsets.zero,
                ),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
