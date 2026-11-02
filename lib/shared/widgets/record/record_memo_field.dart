import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/record/record_field_label.dart';

/// Figma COM-04 메모: 최대 [maxLength]자, 글자 수 실시간 표시
class RecordMemoField extends StatelessWidget {
  const RecordMemoField({
    super.key,
    required this.controller,
    required this.hintText,
    this.maxLength = 1000,
    this.enabled = true,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final bool enabled;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const RecordFieldLabel(label: '메모'),
        const SizedBox(height: AppSpacing.spacing2),
        Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
            vertical: AppSpacing.spacing3,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: TextField(
            key: fieldKey,
            controller: controller,
            enabled: enabled,
            minLines: 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
            style: style,
            cursorColor: AppColors.accentsBrand,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: style.copyWith(color: AppColors.foregroundQuaternary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing2),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) => Text(
            '${value.text.characters.length}/$maxLength',
            textAlign: TextAlign.right,
            style: AppTypography.bodySmR.copyWith(
              color: AppColors.foregroundTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
