import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_models.dart';

/// 수량 − [입력] + 와 단위 선택 (COM-POP-01 · MO-MEAL-030 · 040 · 050 공통 인라인 컴포넌트)
///
/// 버튼·단위 변경은 최솟값 1 아래로 내려가지 않고, 직접 입력 중인 1 미만 값은
/// 그대로 두되 [MealEntry.amount] 로만 전달해서 화면에서 추가/저장 버튼을 막게 함
class MealAmountField extends StatefulWidget {
  const MealAmountField({
    super.key,
    required this.entry,
    required this.onChanged,
    this.keyPrefix = 'meal',
  });

  final MealEntry entry;
  final ValueChanged<MealEntry> onChanged;

  /// 한 화면에 여러 개 있을 때 테스트용 키 구분
  final String keyPrefix;

  @override
  State<MealAmountField> createState() => _MealAmountFieldState();
}

class _MealAmountFieldState extends State<MealAmountField> {
  late final TextEditingController _controller = TextEditingController(
    text: formatMealNumber(widget.entry.amount),
  );

  MealEntry get _entry => widget.entry;

  double get _step => _entry.unit == MealUnit.gram ? 10 : 0.5;

  @override
  void didUpdateWidget(covariant MealAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 다른 화면(030 ↔ 040)에서 바뀐 값이 들어오면 입력칸도 맞춤
    final current = double.tryParse(_controller.text);
    if ((current ?? 0) != widget.entry.amount) {
      _controller.text = formatMealNumber(widget.entry.amount);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setAmount(double amount) {
    final value = amount < MealPolicy.minAmount ? MealPolicy.minAmount : amount;
    _controller.text = formatMealNumber(value);
    widget.onChanged(_entry.copyWith(amount: value));
  }

  void _onTyped(String text) {
    final value = double.tryParse(text);
    widget.onChanged(
      _entry.copyWith(amount: value == null || value < 0 ? 0 : value),
    );
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
    final value = amount < MealPolicy.minAmount ? MealPolicy.minAmount : amount;
    _controller.text = formatMealNumber(value);
    widget.onChanged(_entry.copyWith(unit: unit, amount: value));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.keyPrefix;
    return Row(
      children: [
        Expanded(
          child: MealNumberInput(
            controller: _controller,
            decreaseKey: ValueKey('$p-amount-dec'),
            increaseKey: ValueKey('$p-amount-inc'),
            fieldKey: ValueKey('$p-amount-field'),
            onDecrease: () => _setAmount(_entry.amount - _step),
            onIncrease: () => _setAmount(_entry.amount + _step),
            onChanged: _onTyped,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing3),
        MealUnitSelect(
          key: ValueKey('$p-unit-select'),
          unit: _entry.unit,
          servingUnit: _entry.food.servingUnit,
          onChanged: _setUnit,
        ),
      ],
    );
  }
}

/// − [수량] + (NumberInput)
class MealNumberInput extends StatelessWidget {
  const MealNumberInput({
    super.key,
    required this.controller,
    required this.onDecrease,
    required this.onIncrease,
    required this.onChanged,
    this.decreaseKey,
    this.increaseKey,
    this.fieldKey,
  });

  final TextEditingController controller;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final ValueChanged<String> onChanged;
  final Key? decreaseKey;
  final Key? increaseKey;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );

    Widget stepButton(String symbol, String label, Key? key, VoidCallback onTap) =>
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
          stepButton('−', '줄이기', decreaseKey, onDecrease),
          separator,
          Expanded(
            child: TextField(
              key: fieldKey,
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
          stepButton('+', '늘리기', increaseKey, onIncrease),
        ],
      ),
    );
  }
}

/// 단위 선택 (Select). g 단위는 음식 기준 단위(g / ml)로 표시
class MealUnitSelect extends StatelessWidget {
  const MealUnitSelect({
    super.key,
    required this.unit,
    required this.onChanged,
    this.servingUnit = 'g',
  });

  final MealUnit unit;
  final ValueChanged<MealUnit> onChanged;
  final String servingUnit;

  String _label(MealUnit u) => u == MealUnit.gram ? servingUnit : u.label;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );

    return PopupMenuButton<MealUnit>(
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
          PopupMenuItem(value: u, child: Text(_label(u), style: style)),
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
            Expanded(child: Text(_label(unit), style: style)),
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

/// 칼로리 + 탄 / 단 / 지 배지 (COM-POP-01 · MO-MEAL-030 공통)
class MealMacroRow extends StatelessWidget {
  const MealMacroRow({super.key, required this.entry});

  final MealEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '${formatMealNumber(entry.kcal.roundToDouble())}kcal',
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
                _Macro(label: '탄', grams: entry.carbs),
                const SizedBox(width: AppSpacing.spacing6),
                _Macro(label: '단', grams: entry.protein),
                const SizedBox(width: AppSpacing.spacing6),
                _Macro(label: '지', grams: entry.fat),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.label, required this.grams});

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
