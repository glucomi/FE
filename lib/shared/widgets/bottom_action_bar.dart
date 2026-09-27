import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

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
      child: AppButton(
        label: label,
        onPressed: onPressed,
      ),
    );
  }
}