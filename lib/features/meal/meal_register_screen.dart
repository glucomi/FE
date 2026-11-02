import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/widgets/meal_amount_field.dart';
import 'package:glucomi/features/meal/widgets/meal_form_widgets.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// MO-MEAL-050 직접 등록
///
/// 저장하기를 누르면 서버에 등록한 뒤 등록된 [MealFood] 를 돌려주며 닫힘.
/// 필수: 음식명 · 섭취량 · 열량 (나머지 영양성분은 비워도 저장 가능)
class MealRegisterScreen extends StatefulWidget {
  const MealRegisterScreen({
    super.key,
    required this.repository,
    this.initialName = '',
  });

  final MealFoodRepository repository;

  /// 검색어에서 넘어온 기본 음식명
  final String initialName;

  @override
  State<MealRegisterScreen> createState() => _MealRegisterScreenState();
}

/// 영양성분 입력 칸 정의
typedef _NutrientField = ({String key, String label, String unit, bool sub});

class _MealRegisterScreenState extends State<MealRegisterScreen> {
  static const List<List<_NutrientField>> _groups = [
    [(key: 'kcal', label: '열량', unit: 'kcal', sub: false)],
    [
      (key: 'carbs', label: '탄수화물', unit: 'g', sub: false),
      (key: 'sugar', label: '당류', unit: 'g', sub: true),
      (key: 'fiber', label: '식이섬유', unit: 'g', sub: true),
    ],
    [(key: 'protein', label: '단백질', unit: 'g', sub: false)],
    [
      (key: 'fat', label: '지방', unit: 'g', sub: false),
      (key: 'saturatedFat', label: '포화지방', unit: 'g', sub: true),
      (key: 'transFat', label: '트랜스지방', unit: 'g', sub: true),
      (key: 'fattyAcid', label: '지방산', unit: 'g', sub: true),
      (key: 'unsaturatedFat', label: '불포화지방산', unit: 'g', sub: true),
    ],
    [(key: 'cholesterol', label: '콜레스테롤', unit: 'mg', sub: false)],
    [(key: 'sodium', label: '나트륨', unit: 'mg', sub: false)],
    [(key: 'caffeine', label: '카페인', unit: 'mg', sub: false)],
  ];

  final _brandController = TextEditingController();
  late final _nameController = TextEditingController(text: widget.initialName);
  late final _amountController = TextEditingController(text: '100');
  final Map<String, TextEditingController> _nutrients = {
    for (final group in _groups)
      for (final field in group) field.key: TextEditingController(),
  };

  String _servingUnit = 'g';
  bool _saving = false;

  double? _value(String key) => double.tryParse(_nutrients[key]!.text);
  double get _amount => double.tryParse(_amountController.text) ?? 0;

  bool get _canSave =>
      !_saving &&
      _nameController.text.trim().isNotEmpty &&
      _amount >= MealPolicy.minAmount &&
      _value('kcal') != null;

  @override
  void dispose() {
    _brandController.dispose();
    _nameController.dispose();
    _amountController.dispose();
    for (final c in _nutrients.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _stepAmount(double delta) {
    final next = _amount + delta;
    setState(() {
      _amountController.text = formatMealNumber(
        next < MealPolicy.minAmount ? MealPolicy.minAmount : next,
      );
    });
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final brand = _brandController.text.trim();
    final draft = MealFood(
      id: '',
      name: _nameController.text.trim(),
      source: MealFoodSource.user,
      brand: brand.isEmpty ? null : brand,
      servingGram: _amount,
      servingUnit: _servingUnit,
      kcal: _value('kcal')!,
      carbs: _value('carbs') ?? 0,
      protein: _value('protein') ?? 0,
      fat: _value('fat') ?? 0,
      sugar: _value('sugar'),
      fiber: _value('fiber'),
      saturatedFat: _value('saturatedFat'),
      transFat: _value('transFat'),
      fattyAcid: _value('fattyAcid'),
      unsaturatedFat: _value('unsaturatedFat'),
      cholesterol: _value('cholesterol'),
      sodium: _value('sodium'),
      caffeine: _value('caffeine'),
    );

    setState(() => _saving = true);
    final MealFood created;
    try {
      created = await widget.repository.createCustomFood(draft);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      final message = e is ApiException ? e.message : '음식을 등록하지 못했어요.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    if (mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      body: SafeArea(
        child: Column(
          children: [
            // ① 입력 중 이탈해도 별도 확인 없음
            AppHeaderBar(
              title: '직접 등록',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing2),
                children: [
                  _Section(
                    children: [
                      const MealFieldLabel(label: '브랜드명'),
                      const SizedBox(height: AppSpacing.spacing2),
                      _TextBox(
                        key: const ValueKey('meal-register-brand'),
                        controller: _brandController,
                        hint: '브랜드명을 입력해주세요',
                        height: AppSpacing.controlHeightLg,
                        horizontalPadding: AppSpacing.spacing2,
                        onChanged: (_) {},
                      ),
                      const SizedBox(height: AppSpacing.spacing6),
                      const MealFieldLabel(label: '음식명', required: true),
                      const SizedBox(height: AppSpacing.spacing2),
                      _TextBox(
                        key: const ValueKey('meal-register-name'),
                        controller: _nameController,
                        hint: '음식명을 입력해주세요',
                        height: AppSpacing.controlHeightXl,
                        horizontalPadding: AppSpacing.spacing4,
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing2),
                  _Section(
                    children: [
                      const MealFieldLabel(label: '섭취량', required: true),
                      const SizedBox(height: AppSpacing.spacing2),
                      Row(
                        children: [
                          Expanded(
                            child: MealNumberInput(
                              controller: _amountController,
                              decreaseKey: const ValueKey('meal-register-amount-dec'),
                              increaseKey: const ValueKey('meal-register-amount-inc'),
                              fieldKey: const ValueKey('meal-register-amount-field'),
                              onDecrease: () => _stepAmount(-10),
                              onIncrease: () => _stepAmount(10),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spacing3),
                          _ServingUnitSelect(
                            unit: _servingUnit,
                            onChanged: (u) => setState(() => _servingUnit = u),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing2),
                  _Section(
                    gap: AppSpacing.spacing3,
                    children: [
                      for (final (gi, group) in _groups.indexed) ...[
                        if (gi > 0)
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.borderDefault,
                          ),
                        for (final field in group)
                          _NutrientInput(
                            key: ValueKey('meal-register-${field.key}'),
                            label: field.label,
                            unit: field.unit,
                            sub: field.sub,
                            required: field.key == 'kcal',
                            controller: _nutrients[field.key]!,
                            onChanged: () => setState(() {}),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            BottomActionBar(
              label: '저장하기',
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.children, this.gap = 0});

  final List<Widget> children;

  /// 자식 사이 간격 (0 이면 자식이 직접 간격을 가짐)
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: const BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.borderDefault),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: gap,
        children: children,
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox({
    super.key,
    required this.controller,
    required this.hint,
    required this.height,
    required this.horizontalPadding,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final double height;
  final double horizontalPadding;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: style,
        cursorColor: AppColors.accentsBrand,
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: style.copyWith(color: AppColors.foregroundQuaternary),
        ),
      ),
    );
  }
}

/// 영양성분 한 줄: 라벨 + 숫자 입력칸(단위)
class _NutrientInput extends StatelessWidget {
  const _NutrientInput({
    super.key,
    required this.label,
    required this.unit,
    required this.controller,
    required this.onChanged,
    this.sub = false,
    this.required = false,
  });

  final String label;
  final String unit;
  final TextEditingController controller;
  final VoidCallback onChanged;
  final bool sub;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final inputStyle = AppTypography.bodyLgM.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (sub) ...[
                SvgPicture.asset(
                  'assets/meal/arrow_bottom_right.svg',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: AppSpacing.spacing15),
              ],
              Text(
                label,
                style: AppTypography.bodyMdM.copyWith(
                  color: sub
                      ? AppColors.foregroundTertiary
                      : AppColors.foregroundPrimary,
                ),
              ),
              if (required) ...[
                const SizedBox(width: AppSpacing.spacing05),
                Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: SvgPicture.asset(
                    'assets/meal/required_mark.svg',
                    width: 8,
                    height: 8,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.spacing2),
        Container(
          width: 160,
          height: AppSpacing.controlHeightLg,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (_) => onChanged(),
                  textAlign: TextAlign.right,
                  style: inputStyle,
                  cursorColor: AppColors.accentsBrand,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                unit,
                style: inputStyle.copyWith(color: AppColors.foregroundQuaternary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 기준 섭취량 단위 (g / ml). 공통 인라인 컴포넌트와 같이 탭하면 순환
class _ServingUnitSelect extends StatelessWidget {
  const _ServingUnitSelect({required this.unit, required this.onChanged});

  final String unit;
  final ValueChanged<String> onChanged;

  static const _units = ['g', 'ml'];

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );
    final next = _units[(_units.indexOf(unit) + 1) % _units.length];
    return Semantics(
      button: true,
      label: '단위 $unit, 탭하면 $next(으)로 바뀜',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('meal-register-unit'),
        onTap: () => onChanged(next),
        behavior: HitTestBehavior.opaque,
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
              Expanded(child: Text(unit, style: style)),
              SvgPicture.asset(
                'assets/meal/chevron_down.svg',
                width: 20,
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
