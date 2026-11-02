import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 입력 필드 라벨 + (필수) 초록 점
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({super.key, required this.label, this.required = false});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
            'assets/common/required_mark.svg',
            width: 8,
            height: 8,
          ),
        ],
      ],
    );
  }
}
