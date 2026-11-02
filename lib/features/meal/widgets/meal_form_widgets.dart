import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 라벨 + (필수) 초록 점
class MealFieldLabel extends StatelessWidget {
  const MealFieldLabel({super.key, required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            'assets/meal/required_mark.svg',
            width: 8,
            height: 8,
          ),
        ],
      ],
    );
  }
}

/// + 아이콘 외곽선 버튼 (사진 추가하기 / 메뉴 추가하기)
class MealOutlineAddButton extends StatelessWidget {
  const MealOutlineAddButton({super.key, required this.label, this.onTap});

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
          height: AppSpacing.controlHeightLg,
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/meal/plus_20.svg', width: 20, height: 20),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                label,
                style: AppTypography.btnMd.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
