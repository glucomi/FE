import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/widgets/meal_search_panels.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';

/// 담은 음식 목록 + 기록하기 버튼 (COM-POP-02)
class MealCartBar extends StatelessWidget {
  const MealCartBar({
    super.key,
    required this.entries,
    required this.onRemove,
    required this.onEdit,
    required this.onSubmit,
  });

  final List<MealEntry> entries;
  final ValueChanged<MealEntry> onRemove;
  final ValueChanged<MealEntry> onEdit;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      bottomPadding: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.spacing2,
            runSpacing: AppSpacing.spacing1,
            children: [
              for (final entry in entries)
                _FoodChip(
                  entry: entry,
                  onTap: () => onEdit(entry),
                  onRemove: () => onRemove(entry),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          SizedBox(
            height: AppSpacing.controlHeightXl,
            child: Align(
              alignment: Alignment.topCenter,
              child: MealPrimaryButton(
                key: const ValueKey('meal-submit'),
                label: '기록하기',
                count: entries.length,
                onTap: onSubmit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodChip extends StatelessWidget {
  const _FoodChip({
    required this.entry,
    required this.onTap,
    required this.onRemove,
  });

  final MealEntry entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.controlHeightSm,
      padding: const EdgeInsets.only(
        left: AppSpacing.spacing3,
        right: AppSpacing.spacing2,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralsSurface,
        border: Border.all(
          color: AppColors.borderDefault,
          width: AppTokens.borderWidthThin,
        ),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Text(
              entry.food.name,
              style: AppTypography.labelBadge.copyWith(
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing1),
          Semantics(
            button: true,
            label: '${entry.food.name} 빼기',
            child: GestureDetector(
              key: ValueKey('meal-chip-remove-${entry.food.id}'),
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              child: SvgPicture.asset(
                'assets/meal/chip_close.svg',
                width: 16,
                height: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
