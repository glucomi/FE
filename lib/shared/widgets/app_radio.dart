import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 20x20 라디오 (Radio 컴포넌트)
class AppRadio extends StatelessWidget {
  const AppRadio({super.key, required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.neutralsSurface,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.accentsBrand : AppColors.borderStrong,
          width: selected
              ? AppTokens.borderWidthThick
              : AppTokens.borderWidthMedium,
        ),
      ),
      child: selected
          ? Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppColors.accentsBrand,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
