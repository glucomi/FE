import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_icons.dart';

class AppHeaderBar extends StatelessWidget {
  const AppHeaderBar({
    super.key,
    this.title = '',
    this.onBack,
    this.iconLeft,
    this.iconRight1,
    this.iconRight2,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? iconLeft;
  final Widget? iconRight1;
  final Widget? iconRight2;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.controlHeightXl,
      color: AppColors.neutralsBackground,
      foregroundDecoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.borderDefault,
            width: AppTokens.borderWidthDefault,
          ),
        ),
      ),
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (iconLeft != null || onBack != null)
            Positioned(
              left: AppSpacing.spacing4,
              child:
                  iconLeft ??
                  GestureDetector(
                    onTap: onBack,
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: AppChevronLeft(),
                    ),
                  ),
            ),
          SizedBox(
            width: 200,
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.headingH2.copyWith(
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
          Positioned(
            right: AppSpacing.spacing4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ?iconRight1,
                if (iconRight1 != null && iconRight2 != null)
                  const SizedBox(width: AppSpacing.spacing2),
                ?iconRight2,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
