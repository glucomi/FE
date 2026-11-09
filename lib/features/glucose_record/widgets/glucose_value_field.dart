import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/glucose_record/glucose_record_models.dart';
import 'package:glucomi/shared/widgets/app_field_label.dart';

/// 혈당값 (mg/dL) 필수 라벨 + 56px 숫자 입력칸
class GlucoseValueField extends StatelessWidget {
  const GlucoseValueField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onEditingComplete,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Figma: 라벨 줄 높이 25
        const SizedBox(
          height: 25,
          child: Align(
            alignment: Alignment.centerLeft,
            child: AppFieldLabel(label: '혈당 값(mg/dL)', required: true),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing3),
        Container(
          height: AppSpacing.controlHeightXl,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: TextField(
            key: const ValueKey('glucose-value'),
            controller: controller,
            focusNode: focusNode,
            onEditingComplete: onEditingComplete,
            onTapOutside: (_) => focusNode?.unfocus(),
            readOnly: readOnly,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              const GlucoseValueInputFormatter(),
            ],
            style: style,
            cursorColor: AppColors.accentsBrand,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: '혈당값을 입력해주세요',
              hintStyle: style.copyWith(color: AppColors.foregroundQuaternary),
            ),
          ),
        ),
      ],
    );
  }
}
