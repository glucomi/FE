import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// Figma Button/Pill — 당뇨 유형 선택지
class DiabetesTypeOption extends StatelessWidget {
  const DiabetesTypeOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.accentsBrand
        : AppColors.foregroundSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing5,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: selected ? AppColors.tintBrand : AppColors.neutralsBackground,
              borderRadius: BorderRadius.circular(AppRadius.radiusFull),
              border: Border.all(
                color: selected
                    ? AppColors.focusRingBrand
                    : AppColors.borderDefault,
                width: AppTokens.borderWidthDefault,
              ),
            ),
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/signup/check_on.svg',
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(
                    selected ? AppColors.accentsBrand : AppColors.borderStrong,
                    BlendMode.srcIn,
                  ),
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: AppSpacing.spacing15),
                ExcludeSemantics(
                  child: Text(
                    label,
                    style: AppTypography.btnMd.copyWith(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
