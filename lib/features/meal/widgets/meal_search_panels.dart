import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// "찾고 계신 ‘밥’이 없으신가요?" 직접 등록 안내 카드 (Dialog)
class MealRegisterSuggestion extends StatelessWidget {
  const MealRegisterSuggestion({
    super.key,
    required this.query,
    required this.onRegister,
  });

  final String query;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing2,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing1,
        ),
        decoration: BoxDecoration(
          color: AppColors.neutralsBackground,
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.radiusXl),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.spacing4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '찾고 계신 ‘$query’이 없으신가요?',
                      style: AppTypography.bodyMdM.copyWith(
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing05),
                    Text(
                      '한번만 등록하면 계속 활용할 수 있어요',
                      style: AppTypography.bodySmR.copyWith(
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacing2),
            GestureDetector(
              key: const ValueKey('meal-suggest-register'),
              onTap: onRegister,
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: AppSpacing.controlHeightMd,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing4,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.neutralsSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                ),
                child: Text(
                  '직접 등록',
                  style: AppTypography.btnMd.copyWith(
                    color: AppColors.foregroundPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 검색 요령 안내 (Alert)
class MealSearchTips extends StatelessWidget {
  const MealSearchTips({super.key});

  @override
  Widget build(BuildContext context) {
    final bulletStyle = AppTypography.bodySmR.copyWith(
      color: AppColors.foregroundTertiary,
    );

    Widget bullet(String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 18, child: Text('  •', style: bulletStyle)),
        Expanded(child: Text(text, style: bulletStyle)),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        decoration: BoxDecoration(
          color: AppColors.neutralsSubtle,
          border: Border.all(color: AppColors.borderStrong),
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SvgPicture.asset('assets/meal/info.svg', width: 20, height: 20),
                const SizedBox(width: AppSpacing.spacing2),
                Text(
                  '이렇게 해보는건 어때요?',
                  style: AppTypography.bodyMdM.copyWith(
                    color: AppColors.foregroundPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.spacing1),
            bullet('키워드에 오타가 없는지 확인해보세요'),
            bullet('일반적인 키워드로 검색해보세요\n( 예시 : 스위트칠리소스 → 칠리소스 )'),
          ],
        ),
      ),
    );
  }
}

/// 직접 등록 탭 아래쪽 "+ 직접 등록" 버튼
class MealRegisterButton extends StatelessWidget {
  const MealRegisterButton({super.key, required this.onTap});

  final VoidCallback onTap;

  /// Figma 버튼 색 (디자인 토큰에 없는 값)
  static const Color _color = Color(0xFF16B09E);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        key: const ValueKey('meal-register-button'),
        onTap: onTap,
        child: Container(
          width: 130,
          height: AppSpacing.controlHeightMd,
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset('assets/meal/plus_16.svg', width: 16, height: 16),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                '직접 등록',
                style: AppTypography.btnMd.copyWith(
                  color: AppColors.foregroundOnAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 초록 버튼 (기록하기 / 추가하기)
class MealPrimaryButton extends StatelessWidget {
  const MealPrimaryButton({
    super.key,
    required this.label,
    this.count,
    this.onTap,
  });

  final String label;

  /// 버튼 안 숫자 배지 (담은 음식 수)
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppSpacing.controlHeightLg,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing5),
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.interactiveBrandDefault
                : AppColors.interactiveBrandDisabled,
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.btnMd.copyWith(
                  color: AppColors.foregroundOnAccent,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: AppSpacing.spacing2),
                Container(
                  height: 24,
                  constraints: const BoxConstraints(minWidth: 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing2,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.interactiveBrandDisabled,
                    borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                  ),
                  child: Text(
                    '$count',
                    style: AppTypography.btnMd.copyWith(
                      color: AppColors.interactiveBrandHover,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
