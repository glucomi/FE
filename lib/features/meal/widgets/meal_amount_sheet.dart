import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/widgets/meal_food_tile.dart';
import 'package:glucomi/features/meal/widgets/meal_search_panels.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';

/// 음식 선택 시 먹은 양 입력 바텀시트 (COM-POP-01). 추가하기를 누르면 [MealEntry] 반환
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
  late final TextEditingController _amountController = TextEditingController(
    text: formatMealNumber(_entry.amount),
  );

  double get _step => _entry.unit == MealUnit.gram ? 10 : 0.5;

  /// COM-POP-01: 수량 최솟값 1 (1 미만 입력 불가)
  static const double _minAmount = 1;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(double amount, {bool updateField = true}) {
    // 버튼·단위 변경은 1 미만으로 내려가지 않게, 직접 입력 중에는 그대로 두고 추가 버튼만 막음
    final value = updateField && amount < _minAmount ? _minAmount : (amount < 0 ? 0.0 : amount);
    setState(() => _entry = _entry.copyWith(amount: value));
    if (updateField) _amountController.text = formatMealNumber(value);
  }

  void _setUnit(MealUnit unit) {
    if (unit == _entry.unit) return;
    final serving = _entry.food.servingGram;
    final amount = switch (unit) {
      MealUnit.gram => (_entry.amount * serving).roundToDouble(),
      // 0.5인분 단위로 맞춤
      MealUnit.serving =>
        serving == 0 ? 1.0 : ((_entry.amount / serving) * 2).round() / 2,
    };
    setState(() => _entry = _entry.copyWith(unit: unit));
    _setAmount(amount < _minAmount ? _minAmount : amount);
  }

  void _toggleFavorite() {
    setState(() => _favorite = !_favorite);
    widget.onFavoriteChanged(_favorite);
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _entry.amount >= _minAmount;

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
                label: '영양정보',
                onTap: widget.onNutritionInfo,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Row(
            children: [
              Expanded(
                child: _NumberInput(
                  controller: _amountController,
                  onDecrease: () => _setAmount(_entry.amount - _step),
                  onIncrease: () => _setAmount(_entry.amount + _step),
                  onChanged: (text) {
                    final value = double.tryParse(text);
                    if (value != null) _setAmount(value, updateField: false);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.spacing3),
              _UnitSelect(unit: _entry.unit, onChanged: _setUnit),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
          const SizedBox(height: AppSpacing.spacing4),
          Row(
            children: [
              Text(
                '${formatMealNumber(_entry.kcal.roundToDouble())}kcal',
                style: AppTypography.headingH3.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing4),
              // 좁은 화면에서는 탄단지 줄을 줄여서 한 줄 유지
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    children: [
                      _Nutrient(label: '탄', grams: _entry.carbs),
                      const SizedBox(width: AppSpacing.spacing6),
                      _Nutrient(label: '단', grams: _entry.protein),
                      const SizedBox(width: AppSpacing.spacing6),
                      _Nutrient(label: '지', grams: _entry.fat),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
  const _OutlinedSmallButton({required this.label, this.onTap});

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

/// − [수량] + (NumberInput)
class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.controller,
    required this.onDecrease,
    required this.onIncrease,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );

    Widget stepButton(String symbol, String label, Key key, VoidCallback onTap) =>
        Semantics(
          button: true,
          label: label,
          child: GestureDetector(
            key: key,
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(child: Text(symbol, style: style)),
            ),
          ),
        );

    const separator = SizedBox(
      width: 1,
      height: 28.8,
      child: ColoredBox(color: AppColors.borderDefault),
    );

    return Container(
      height: AppSpacing.controlHeightXl,
      decoration: BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: Row(
        children: [
          stepButton('−', '줄이기', const ValueKey('meal-amount-dec'), onDecrease),
          separator,
          Expanded(
            child: TextField(
              key: const ValueKey('meal-amount-field'),
              controller: controller,
              onChanged: onChanged,
              textAlign: TextAlign.center,
              style: style,
              cursorColor: AppColors.accentsBrand,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d?')),
              ],
              decoration: const InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
              ),
            ),
          ),
          separator,
          stepButton('+', '늘리기', const ValueKey('meal-amount-inc'), onIncrease),
        ],
      ),
    );
  }
}

/// 단위 선택 (Select)
class _UnitSelect extends StatelessWidget {
  const _UnitSelect({required this.unit, required this.onChanged});

  final MealUnit unit;
  final ValueChanged<MealUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );

    return PopupMenuButton<MealUnit>(
      key: const ValueKey('meal-unit-select'),
      onSelected: onChanged,
      tooltip: '단위 선택',
      position: PopupMenuPosition.under,
      color: AppColors.neutralsBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      constraints: const BoxConstraints.tightFor(width: 120),
      itemBuilder: (context) => [
        for (final u in MealUnit.values)
          PopupMenuItem(value: u, child: Text(u.label, style: style)),
      ],
      child: Container(
        width: 120,
        height: AppSpacing.controlHeightXl,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
        decoration: BoxDecoration(
          color: AppColors.neutralsBackground,
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
        ),
        child: Row(
          children: [
            Expanded(child: Text(unit.label, style: style)),
            SvgPicture.asset(
              'assets/meal/chevron_down.svg',
              width: 20,
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// 탄 / 단 / 지 배지 + 그램
class _Nutrient extends StatelessWidget {
  const _Nutrient({required this.label, required this.grams});

  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.neutralsSubtle,
            shape: BoxShape.circle,
          ),
          child: Text(
            label,
            style: AppTypography.labelBadge.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing1),
        Text(
          '${formatMealNumber(grams.roundToDouble())}g',
          style: AppTypography.bodySmM.copyWith(
            color: AppColors.foregroundPrimary,
          ),
        ),
      ],
    );
  }
}
