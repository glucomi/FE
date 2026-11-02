import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/shared/widgets/app_radio.dart';

/// 음식 목록 한 줄 (COM-001)
///
/// MO-MEAL-020: 왼쪽 텍스트 영역 탭 → [onTap] (음식 상세 MO-MEAL-030),
/// 오른쪽 선택 버튼 탭 → [onSelect] (수량 입력 COM-POP-01)
class MealFoodTile extends StatelessWidget {
  const MealFoodTile({
    super.key,
    required this.food,
    this.selected = false,
    this.onTap,
    this.onSelect,
  });

  final MealFood food;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: AppSpacing.spacing5),
      decoration: const BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: '${food.name} 상세 보기',
              child: GestureDetector(
                key: ValueKey('meal-food-detail-${food.id}'),
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.spacing4,
                  ),
                  child: MealFoodSummary(food: food),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            selected: selected,
            label: '${food.name} 선택',
            child: GestureDetector(
              key: ValueKey('meal-food-select-${food.id}'),
              onTap: onSelect,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.spacing2,
                  AppSpacing.spacing4,
                  AppSpacing.spacing5,
                  AppSpacing.spacing4,
                ),
                child: AppRadio(selected: selected),
              ),
            ),
          ),
        ],
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
                        '${formatMealNumber(food.servingGram)}${food.servingUnit}',
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
