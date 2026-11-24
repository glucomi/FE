import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

/// COM-POP-12 권한 안내 모달 (MO-CAMERA-010 (d) 자체모달)
///
/// '설정으로 이동' 탭 시 기기 설정 앱을 엶 (웹은 브라우저 설정 안내 토스트)
Future<void> showPermissionDialog(
  BuildContext context, {
  String title = '갤러리 접근 권한이 꺼져있어요',
  String message = '설정에서 허용하면\n사진을 불러와 기록 할 수 있어요',
}) async {
  final openSettings = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => Dialog(
      key: const ValueKey('permission-dialog'),
      insetPadding: const EdgeInsets.symmetric(horizontal: 35),
      backgroundColor: AppColors.neutralsBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.radius2xl),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodyLgM.copyWith(
                color: AppColors.foregroundPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing1),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmR.copyWith(
                color: AppColors.foregroundTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      foregroundColor: AppColors.foregroundPrimary,
                      side: const BorderSide(color: AppColors.borderDefault),
                    ),
                    child: const Text('닫기'),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing3),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('permission-open-settings'),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      backgroundColor: AppColors.accentsBrand,
                    ),
                    child: const Text('설정으로 이동'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  if (openSettings != true || !context.mounted) return;

  var opened = false;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    opened = await launchUrl(Uri.parse('app-settings:'));
  }
  if (!opened && context.mounted) {
    showAppToast(context, '브라우저 또는 기기 설정에서 사진 접근을 허용해 주세요.');
  }
}
