import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 오후 02:03
String formatFieldTime(TimeOfDay t) {
  final period = t.hour < 12 ? '오전' : '오후';
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  String two(int v) => v.toString().padLeft(2, '0');
  return '$period ${two(hour)}:${two(t.minute)}';
}

/// Figma COM-03 (시간): 라벨 + 48px 선택 박스. [AppDateField] 와 짝
class RecordTimeField extends StatelessWidget {
  const RecordTimeField({
    super.key,
    required this.time,
    this.onTap,
    this.label = '시간',
  });

  final TimeOfDay time;

  /// 없으면 탭할 수 없음
  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = formatFieldTime(time);
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
            Text(
              label,
              style: AppTypography.labelMeta.copyWith(
                color: AppColors.foregroundPrimary,
              ),
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
                    'assets/record/time.svg',
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
