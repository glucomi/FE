import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 내 목록 카드 (Figma List/내 복용약): 제목 · 보조정보 + 오른쪽 위 삭제(X)
class SavedItemCard extends StatelessWidget {
  const SavedItemCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.onDelete,
  });

  final String title;

  /// 비어 있으면 '-' 표시
  final String subtitle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    // 카드 여백을 Stack 안쪽으로 넣어서 X 버튼 전체가 터치 영역 안에 들어오게 함
    // (여백 밖에 걸쳐 있으면 버튼 오른쪽 절반이 눌리지 않음)
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacing4 + AppSpacing.spacing1,
              AppSpacing.spacing3 + AppSpacing.spacing1,
              AppSpacing.spacing4 + AppSpacing.spacing8,
              AppSpacing.spacing4 + AppSpacing.spacing1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headingH3.copyWith(
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing1),
                Text(
                  subtitle.isEmpty ? '-' : subtitle,
                  style: AppTypography.labelBadge.copyWith(
                    color: AppColors.foregroundQuaternary,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: AppSpacing.spacing3 - 4,
            right: AppSpacing.spacing4 - 16,
            child: Semantics(
              button: true,
              label: '$title 삭제',
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onDelete,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: AppSpacing.controlHeightSm,
                  height: AppSpacing.controlHeightSm,
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/record/delete_16.svg',
                      width: 16,
                      height: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
