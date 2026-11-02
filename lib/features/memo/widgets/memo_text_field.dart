import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// Figma COM-04 (메모): 라벨 + 여러 줄 입력 + 글자 수 (n/최대)
class MemoTextField extends StatelessWidget {
  const MemoTextField({
    super.key,
    required this.controller,
    required this.maxLength,
    this.hintText = '메모를 입력해주세요.',
    this.readOnly = false,
    this.label = '메모',
  });

  final TextEditingController controller;
  final int maxLength;
  final String hintText;

  /// (c) 등록후처럼 보기만 할 때
  final bool readOnly;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTypography.labelMeta.copyWith(
            color: AppColors.foregroundPrimary,
          ),
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
            key: const ValueKey('memo-text'),
            controller: controller,
            readOnly: readOnly,
            maxLines: null,
            minLines: 4,
            keyboardType: TextInputType.multiline,
            // 최대 길이를 넘는 입력은 막음 (붙여넣기도 앞에서부터 잘림)
            inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
            style: AppTypography.bodyMdR.copyWith(
              color: AppColors.foregroundPrimary,
            ),
            cursorColor: AppColors.accentsBrand,
            decoration: InputDecoration.collapsed(
              hintText: hintText,
              hintStyle: AppTypography.bodyMdR.copyWith(
                color: AppColors.foregroundQuaternary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing2),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => Text(
            '${value.text.characters.length}/$maxLength',
            key: const ValueKey('memo-text-count'),
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
