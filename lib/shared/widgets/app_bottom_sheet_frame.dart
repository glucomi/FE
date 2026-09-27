import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 바텀시트 공통 틀 (COM-POP): 위쪽 둥근 모서리 + 드래그 핸들 + 여백
class AppBottomSheetFrame extends StatelessWidget {
  const AppBottomSheetFrame({
    super.key,
    required this.child,
    this.bottomPadding = AppSpacing.spacing4,
  });

  final Widget child;

  /// 홈 인디케이터(안전 영역) 위 여백
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border(top: BorderSide(color: AppColors.borderStrong)),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radius3xl),
        ),
        boxShadow: AppShadows.lg,
      ),
      child: Stack(
        children: [
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFBCBCBF),
                  borderRadius: BorderRadius.circular(AppRadius.radius3xl),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.spacing4,
              AppSpacing.spacing10,
              AppSpacing.spacing4,
              bottomPadding + bottomInset,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
