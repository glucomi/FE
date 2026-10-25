import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

/// Figma COM-07. [secondaryLabel] 이 있으면 왼쪽 보조 버튼 + 오른쪽 주 버튼 (btn=2)
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.label,
    this.onPressed,
    this.secondaryLabel,
    this.onSecondaryPressed,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondaryPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
      ),
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.borderDefault,
            width: AppTokens.borderWidthDefault,
          ),
        ),
      ),
      child: secondaryLabel == null
          ? AppButton(label: label, onPressed: onPressed)
          : Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    label: secondaryLabel!,
                    onPressed: onSecondaryPressed,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing4),
                Expanded(
                  child: AppButton(label: label, onPressed: onPressed),
                ),
              ],
            ),
    );
  }
}
