import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 2026년 04월 30일
String formatFieldDate(DateTime d) =>
    '${d.year}년 ${d.month.toString().padLeft(2, '0')}월 '
    '${d.day.toString().padLeft(2, '0')}일';

/// Figma COM-02 (날짜): 라벨 + 48px 선택 박스
class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.date,
    this.onTap,
    this.label = '날짜',
    this.isRequired = false,
  });

  final DateTime date;

  /// 없으면 탭할 수 없음
  final VoidCallback? onTap;
  final String label;

  /// 필수 항목 표시 (라벨 오른쪽 초록 점)
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final text = formatFieldDate(date);
    return Semantics(
      button: onTap != null,
      label: '$label $text',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelMeta.copyWith(
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                if (isRequired) ...[
                  const SizedBox(width: AppSpacing.spacing05),
                  SvgPicture.asset(
                    'assets/record/required_mark.svg',
                    width: 8,
                    height: 8,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.spacing2),
            Container(
              height: AppSpacing.controlHeightLg,
              padding: const EdgeInsets.all(AppSpacing.spacing2),
              decoration: BoxDecoration(
                color: AppColors.neutralsBackground,
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/weight/calendar.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: AppSpacing.spacing1),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.bodySmM.copyWith(
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
