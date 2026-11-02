import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 입력 항목 라벨 + (필수) 초록 점. 오른쪽에 작은 버튼을 둘 수 있음 (예: 내 복용약)
class RecordFieldLabel extends StatelessWidget {
  const RecordFieldLabel({
    super.key,
    required this.label,
    this.required = false,
    this.trailing,
  });

  final String label;
  final bool required;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final text = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.labelMeta.copyWith(
            color: AppColors.foregroundPrimary,
          ),
        ),
        if (required) ...[
          const SizedBox(width: AppSpacing.spacing05),
          SvgPicture.asset(
            'assets/record/required_mark.svg',
            width: 8,
            height: 8,
          ),
        ],
      ],
    );
    if (trailing == null) return text;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: Align(alignment: Alignment.centerLeft, child: text)),
        trailing!,
      ],
    );
  }
}

/// 라벨 옆 24px 회색 작은 버튼 (Figma Button sm: 내 복용약 / 내 인슐린)
class RecordChipButton extends StatelessWidget {
  const RecordChipButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.neutralsSubtle,
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Text(
            label,
            style: AppTypography.btnSm.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
