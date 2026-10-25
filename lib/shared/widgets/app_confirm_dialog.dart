import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

/// Figma COM-POP-05 삭제 확인. '삭제'를 누르면 true, 취소·바깥 탭은 false
Future<bool> showDeleteConfirmDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: (context) => const _DeleteConfirmDialog(),
  );
  return result ?? false;
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        decoration: BoxDecoration(
          color: AppColors.neutralsBackground,
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.radiusXl),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
              child: Column(
                children: [
                  Text(
                    '정말 삭제하시겠습니까?',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMdM.copyWith(
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing05),
                  Text(
                    '삭제 시 내용은 복구되지 않습니다',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmR.copyWith(
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spacing3),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    key: const ValueKey('confirm-cancel'),
                    label: '취소',
                    height: AppSpacing.controlHeightMd,
                    horizontalPadding: AppSpacing.spacing4,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing3),
                Expanded(
                  child: AppDangerButton(
                    key: const ValueKey('confirm-delete'),
                    label: '삭제',
                    height: AppSpacing.controlHeightMd,
                    horizontalPadding: AppSpacing.spacing4,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
