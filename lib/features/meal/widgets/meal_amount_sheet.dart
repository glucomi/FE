import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/widgets/meal_amount_field.dart';
import 'package:glucomi/features/meal/widgets/meal_food_tile.dart';
import 'package:glucomi/features/meal/widgets/meal_search_panels.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';

/// 음식 선택 시 먹은 양 입력 바텀시트 (COM-POP-01). 추가하기를 누르면 [MealEntry] 반환
///
/// 영양정보를 누르면 시트를 닫고 [onNutritionInfo] 호출 (MO-MEAL-030 이동)
Future<MealEntry?> showMealAmountSheet(
  BuildContext context, {
  required MealEntry initial,
  required bool favorite,
  required ValueChanged<bool> onFavoriteChanged,
  VoidCallback? onNutritionInfo,
}) {
  return showModalBottomSheet<MealEntry>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: MealAmountSheet(
        initial: initial,
        favorite: favorite,
        onFavoriteChanged: onFavoriteChanged,
        onNutritionInfo: onNutritionInfo,
      ),
    ),
  );
}

class MealAmountSheet extends StatefulWidget {
  const MealAmountSheet({
    super.key,
    required this.initial,
    required this.favorite,
    required this.onFavoriteChanged,
    this.onNutritionInfo,
  });

  final MealEntry initial;
  final bool favorite;
  final ValueChanged<bool> onFavoriteChanged;
  final VoidCallback? onNutritionInfo;

  @override
  State<MealAmountSheet> createState() => _MealAmountSheetState();
}

class _MealAmountSheetState extends State<MealAmountSheet> {
  late MealEntry _entry = widget.initial;
  late bool _favorite = widget.favorite;

  void _toggleFavorite() {
    setState(() => _favorite = !_favorite);
    widget.onFavoriteChanged(_favorite);
  }

  void _openDetail() {
    Navigator.of(context).pop();
    widget.onNutritionInfo?.call();
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _entry.amount >= MealPolicy.minAmount;

    return AppBottomSheetFrame(
      bottomPadding: 15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: MealFoodSummary(food: _entry.food, showServing: false),
              ),
              const SizedBox(width: AppSpacing.spacing2),
              _OutlinedSmallButton(
                key: const ValueKey('meal-nutrition-info'),
                label: '영양정보',
                onTap: widget.onNutritionInfo == null ? null : _openDetail,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          MealAmountField(
            entry: _entry,
            onChanged: (entry) => setState(() => _entry = entry),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
          const SizedBox(height: AppSpacing.spacing4),
          MealMacroRow(entry: _entry),
          const SizedBox(height: AppSpacing.spacing4),
          Row(
            children: [
              Semantics(
                button: true,
                selected: _favorite,
                label: '즐겨찾기',
                child: GestureDetector(
                  key: const ValueKey('meal-favorite'),
                  onTap: _toggleFavorite,
                  child: Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.neutralsBackground,
                      border: Border.all(color: AppColors.borderStrong),
                      borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                    ),
                    child: SvgPicture.asset(
                      _favorite
                          ? 'assets/meal/star_on.svg'
                          : 'assets/meal/star_off.svg',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing4),
              Expanded(
                child: MealPrimaryButton(
                  key: const ValueKey('meal-add'),
                  label: '추가하기',
                  onTap: canAdd ? () => Navigator.of(context).pop(_entry) : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlinedSmallButton extends StatelessWidget {
  const _OutlinedSmallButton({super.key, required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: AppSpacing.controlHeightSm,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing3),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.neutralsBackground,
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
        ),
        child: Text(
          label,
          style: AppTypography.btnSm.copyWith(color: AppColors.foregroundPrimary),
        ),
      ),
    );
  }
}
