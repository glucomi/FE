import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_field_label.dart';

/// Figma COM-04 메모: 라벨 + 최소 112 높이 입력칸 + 글자 수 (기본 최대 1000자)
class AppMemoField extends StatelessWidget {
  const AppMemoField({
    super.key,
    required this.controller,
    required this.hintText,
    this.label = '메모',
    this.maxLength = 1000,
    this.readOnly = false,
    this.fieldKey,
    this.counterKey,
  });

  final TextEditingController controller;
  final String hintText;
  final String label;
  final int maxLength;

  /// 등록후(조회) 상태처럼 수정할 수 없을 때
  final bool readOnly;

  /// 테스트용 키 (입력칸 / 글자 수)
  final Key? fieldKey;
  final Key? counterKey;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: AppFieldLabel(label: label),
        ),
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
            readOnly: readOnly,
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
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => Text(
            '${value.text.characters.length}/$maxLength',
            key: counterKey,
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
