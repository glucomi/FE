import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/shared/widgets/app_radio.dart';

/// 음식 목록 한 줄 (COM-01)
class MealFoodTile extends StatelessWidget {
  const MealFoodTile({
    super.key,
    required this.food,
    this.selected = false,
    this.onTap,
  });

  final MealFood food;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing5,
            vertical: AppSpacing.spacing4,
          ),
          decoration: const BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
          ),
          child: Row(
            children: [
              Expanded(child: MealFoodSummary(food: food)),
              const SizedBox(width: AppSpacing.spacing2),
              AppRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// 분류 라벨 + 음식명 (+ 기준량·칼로리). 목록과 바텀시트 상단에서 함께 사용
class MealFoodSummary extends StatelessWidget {
  const MealFoodSummary({super.key, required this.food, this.showServing = true});

  final MealFood food;
  final bool showServing;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.labelBadge.copyWith(
      color: AppColors.foregroundQuaternary,
    );
    final amountStyle = AppTypography.bodyMdM.copyWith(
      color: AppColors.foregroundSecondary,
    );

    // Figma 높이 46 (라벨 11 + 간격 4 + 이름 25 + 위아래 3)
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing1,
        vertical: 3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (final (i, label) in food.labels.indexed) ...[
                if (i > 0) ...[
                  const SizedBox(width: AppSpacing.spacing1),
                  const _Dot(),
                  const SizedBox(width: AppSpacing.spacing1),
                ],
                Text(label, style: labelStyle),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.spacing1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingH3.copyWith(
                    color: AppColors.foregroundPrimary,
                  ),
                ),
              ),
              if (showServing) ...[
                const SizedBox(width: AppSpacing.spacing2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${formatMealNumber(food.servingGram)}g',
                        style: amountStyle,
                      ),
                      const SizedBox(width: AppSpacing.spacing05),
                      const _Dot(),
                      const SizedBox(width: AppSpacing.spacing05),
                      Text(
                        '${formatMealNumber(food.kcal)}kcal',
                        style: amountStyle,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 2,
      decoration: const BoxDecoration(
        color: AppColors.foregroundTertiary,
        shape: BoxShape.circle,
      ),
    );
  }
}
