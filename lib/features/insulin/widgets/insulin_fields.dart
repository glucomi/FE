import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/shared/widgets/record/record_sheets.dart';

/// 투여량 입력 줄: ↳ 투여량 … [ 1 U ] (MO-INSULIN-010 ⑪)
class InsulinDoseInput extends StatelessWidget {
  const InsulinDoseInput({
    super.key,
    required this.controller,
    this.readOnly = false,
    this.fieldKey,
  });

  final TextEditingController controller;
  final bool readOnly;
  final Key? fieldKey;

  /// Figma Field 최소 너비
  static const double fieldWidth = 160;

  @override
  Widget build(BuildContext context) {
    final valueStyle = AppTypography.bodyLgM.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: AppSpacing.spacing2),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/insulin/arrow_bottom_right.svg',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: AppSpacing.spacing15),
                Text(
                  '투여량',
                  style: AppTypography.bodyMdM.copyWith(
                    color: AppColors.foregroundTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing2),
        Container(
          width: fieldWidth,
          height: AppSpacing.controlHeightLg,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  key: fieldKey,
                  controller: controller,
                  readOnly: readOnly,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: const [InsulinDoseInputFormatter()],
                  style: valueStyle,
                  cursorColor: AppColors.accentsBrand,
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                'U',
                style: AppTypography.bodyLgM.copyWith(
                  color: AppColors.foregroundQuaternary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 저장된 인슐린이 없을 때 (COM-POP-06 시트 · 내 인슐린 (a))
class InsulinEmptyMessage extends StatelessWidget {
  const InsulinEmptyMessage({super.key});

  @override
  Widget build(BuildContext context) => const RecordEmptyMessage(
    title: '저장된 인슐린이 없습니다',
    message: '새 인슐린을 추가해주세요',
  );
}
