import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

class AppButton extends StatelessWidget {
  const AppButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.controlHeightLg,
      child: FilledButton(
        onPressed: onPressed,
        style:
            FilledButton.styleFrom(
              backgroundColor: AppColors.interactiveBrandDefault,
              disabledBackgroundColor: AppColors.interactiveBrandDisabled,
              foregroundColor: AppColors.foregroundOnAccent,
              disabledForegroundColor: AppColors.foregroundOnAccent,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing5,
                vertical: AppSpacing.spacing2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              ),
              textStyle: AppTypography.btnMd.copyWith(
                leadingDistribution: TextLeadingDistribution.even,
              ),
              overlayColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              animationDuration: Duration.zero,
            ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.disabled)) {
                  return AppColors.interactiveBrandDisabled;
                }
                if (states.contains(WidgetState.pressed)) {
                  return AppColors.interactiveBrandActive;
                }
                if (states.contains(WidgetState.hovered)) {
                  return AppColors.interactiveBrandHover;
                }
                return AppColors.interactiveBrandDefault;
              }),
              elevation: const WidgetStatePropertyAll(0),
              side: WidgetStateProperty.resolveWith((states) {
                if (!states.contains(WidgetState.disabled) &&
                    states.contains(WidgetState.focused)) {
                  return const BorderSide(
                    color: AppColors.focusRingBrand,
                    width: 3,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  );
                }
                return BorderSide.none;
              }),
            ),
        child: Text(label),
      ),
    );
  }
}

/// Figma Button: Secondary (흰 배경 + border/default). 예: 삭제하기, 취소
class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = AppSpacing.controlHeightLg,
    this.horizontalPadding = AppSpacing.spacing5,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.neutralsBackground,
          foregroundColor: AppColors.foregroundPrimary,
          disabledForegroundColor: AppColors.foregroundQuaternary,
          side: const BorderSide(
            color: AppColors.borderDefault,
            width: AppTokens.borderWidthDefault,
          ),
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          textStyle: AppTypography.btnMd.copyWith(
            leadingDistribution: TextLeadingDistribution.even,
          ),
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          animationDuration: Duration.zero,
        ),
        child: Text(label),
      ),
    );
  }
}

/// Figma Button: Danger (interactive/danger). 예: 삭제 팝업의 '삭제'
class AppDangerButton extends StatelessWidget {
  const AppDangerButton({
    super.key,
    required this.label,
    this.onPressed,
    this.height = AppSpacing.controlHeightLg,
    this.horizontalPadding = AppSpacing.spacing5,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.interactiveDangerDefault,
          disabledBackgroundColor: AppColors.interactiveDangerDisabled,
          foregroundColor: AppColors.foregroundOnAccent,
          disabledForegroundColor: AppColors.foregroundOnAccent,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          textStyle: AppTypography.btnMd.copyWith(
            leadingDistribution: TextLeadingDistribution.even,
          ),
          overlayColor: Colors.transparent,
          splashFactory: NoSplash.splashFactory,
          animationDuration: Duration.zero,
        ),
        child: Text(label),
      ),
    );
  }
}
