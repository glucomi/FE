import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// Figma Input (56px) 한 줄 입력. [maxLength] 를 넘는 입력은 잘라냄
class RecordTextInput extends StatelessWidget {
  const RecordTextInput({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLength,
    this.enabled = true,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String hintText;
  final int? maxLength;
  final bool enabled;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Container(
      height: AppSpacing.controlHeightXl,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: TextField(
        key: fieldKey,
        controller: controller,
        enabled: enabled,
        maxLines: 1,
        inputFormatters: [
          if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
        ],
        style: style,
        cursorColor: AppColors.accentsBrand,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: style.copyWith(color: AppColors.foregroundQuaternary),
        ),
      ),
    );
  }
}
