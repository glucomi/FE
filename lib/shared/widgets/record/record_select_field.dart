import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// Figma Select (56px): 선택값 또는 보조 문구 + 아래 화살표
class RecordSelectField extends StatelessWidget {
  const RecordSelectField({
    super.key,
    required this.placeholder,
    this.value,
    this.onTap,
  });

  final String placeholder;

  /// 없으면 [placeholder] 를 회색으로 표시
  final String? value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return Semantics(
      button: onTap != null,
      label: hasValue ? value : placeholder,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: AppSpacing.controlHeightXl,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
            vertical: AppSpacing.spacing3,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  hasValue ? value! : placeholder,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMdR.copyWith(
                    color: hasValue
                        ? AppColors.foregroundPrimary
                        : AppColors.foregroundQuaternary,
                  ),
                ),
              ),
              SvgPicture.asset(
                'assets/record/chevron_down.svg',
                width: 20,
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
