import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/widgets/meal_amount_field.dart';
import 'package:glucomi/features/meal/widgets/meal_food_tile.dart';
import 'package:glucomi/features/meal/widgets/meal_glucose_gauge.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// MO-MEAL-030 음식 상세 화면
///
/// 추가하기를 누르면 설정한 수량·단위의 [MealEntry] 를 돌려주며 닫힘.
/// 검색 목록·COM-POP-01 에서 들어오면 기본 수량으로 시작하고,
/// MO-MEAL-040 에서 들어오면 그 화면의 수량을 그대로 이어받음
class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({
    super.key,
    required this.repository,
    required this.initial,
    this.onFavoriteChanged,
  });

  final MealFoodRepository repository;
  final MealEntry initial;

  /// 즐겨찾기 등록/해제 후 (목록 새로고침용)
  final VoidCallback? onFavoriteChanged;

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  late MealEntry _entry = widget.initial;
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = widget.repository;
    try {
      // 목록에는 열량만 있을 수 있어서 영양 성분을 채운 상세로 바꿈
      final detailed = await repo.detail(_entry.food);
      final favorite = await repo.isFavorite(detailed);
      if (!mounted) return;
      setState(() {
        _entry = _entry.copyWith(food: detailed);
        _favorite = favorite;
      });
    } catch (e) {
      _showError(e, '음식 정보를 불러오지 못했어요.');
    }
  }

  Future<void> _toggleFavorite() async {
    final next = !_favorite;
    setState(() => _favorite = next);
    try {
      await widget.repository.setFavorite(_entry.food, favorite: next);
      widget.onFavoriteChanged?.call();
    } catch (e) {
      if (mounted) setState(() => _favorite = !next);
      _showError(e, '즐겨찾기를 바꾸지 못했어요.');
    }
  }

  void _showError(Object error, String fallback) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : fallback;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _entry.amount >= MealPolicy.minAmount;

    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing2),
                children: [
                  _Section(child: _buildAmount()),
                  const SizedBox(height: AppSpacing.spacing2),
                  _Section(child: _buildNutrition()),
                ],
              ),
            ),
            BottomActionBar(
              label: '추가하기',
              onPressed: canAdd
                  ? () => Navigator.of(context).pop(_entry)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: MealFoodSummary(food: _entry.food, showServing: false),
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Semantics(
              button: true,
              selected: _favorite,
              label: '즐겨찾기',
              child: GestureDetector(
                key: const ValueKey('meal-detail-favorite'),
                onTap: _toggleFavorite,
                behavior: HitTestBehavior.opaque,
                child: SvgPicture.asset(
                  _favorite
                      ? 'assets/meal/star_on.svg'
                      : 'assets/meal/star_off.svg',
                  width: 32,
                  height: 32,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing4),
        MealAmountField(
          entry: _entry,
          keyPrefix: 'meal-detail',
          onChanged: (entry) => setState(() => _entry = entry),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
        const SizedBox(height: AppSpacing.spacing4),
        MealMacroRow(entry: _entry),
      ],
    );
  }

  Widget _buildNutrition() {
    final e = _entry;
    final f = e.food;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '예상 혈당 변화',
          style: AppTypography.headingH3.copyWith(
            color: AppColors.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing05),
        Text(
          '따당의 데이터를 기반으로 예측한 변화예요',
          style: AppTypography.bodySmR.copyWith(
            color: AppColors.foregroundQuaternary,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        MealGlucoseGauge(delta: estimateGlucoseDelta(e)),
        const SizedBox(height: AppSpacing.spacing4),
        const Divider(height: 1, thickness: 1, color: AppColors.borderDefault),
        const SizedBox(height: AppSpacing.spacing6),
        _ValueRow(
          label: '총 열량',
          value: e.kcal.roundToDouble(),
          unit: 'kcal',
          keyName: 'meal-detail-kcal',
        ),
        const SizedBox(height: AppSpacing.spacing6),
        _MacroRatioBar(entry: e),
        const SizedBox(height: AppSpacing.spacing6),
        _NutrientCard(
          main: _ValueRow(label: '탄수화물', value: e.carbs, unit: 'g'),
          subs: [
            if (f.sugar != null)
              _ValueRow(label: '당류', value: e.scaled(f.sugar)!, unit: 'g', sub: true),
            if (f.fiber != null)
              _ValueRow(label: '식이섬유', value: e.scaled(f.fiber)!, unit: 'g', sub: true),
          ],
        ),
        _NutrientCard(
          main: _ValueRow(label: '단백질', value: e.protein, unit: 'g'),
        ),
        _NutrientCard(
          main: _ValueRow(label: '지방', value: e.fat, unit: 'g'),
          subs: [
            if (f.saturatedFat != null)
              _ValueRow(label: '포화지방', value: e.scaled(f.saturatedFat)!, unit: 'g', sub: true),
            if (f.transFat != null)
              _ValueRow(label: '트랜스지방', value: e.scaled(f.transFat)!, unit: 'g', sub: true),
            if (f.fattyAcid != null)
              _ValueRow(label: '지방산', value: e.scaled(f.fattyAcid)!, unit: 'g', sub: true),
            if (f.unsaturatedFat != null)
              _ValueRow(label: '불포화지방산', value: e.scaled(f.unsaturatedFat)!, unit: 'g', sub: true),
          ],
        ),
        if (f.cholesterol != null)
          _NutrientCard(
            main: _ValueRow(label: '콜레스테롤', value: e.scaled(f.cholesterol)!, unit: 'mg'),
          ),
        _NutrientCard(
          main: _ValueRow(label: '나트륨', value: e.scaled(f.sodium), unit: 'mg'),
          last: f.caffeine == null,
        ),
        if (f.caffeine != null)
          _NutrientCard(
            main: _ValueRow(label: '카페인', value: e.scaled(f.caffeine)!, unit: 'mg'),
            last: true,
          ),
      ],
    );
  }
}

/// 흰 배경 + 위아래 구분선 섹션
class _Section extends StatelessWidget {
  const _Section({required this.child});

  final Widget child;

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
      child: child,
    );
  }
}

/// 영양성분 소수점 둘째 자리까지 (20.12 / 55)
String formatNutrient(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\.?0+$'), '');
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({
    required this.label,
    required this.value,
    required this.unit,
    this.sub = false,
    this.keyName,
  });

  final String label;

  /// 값이 없으면 '-' 로 표시
  final double? value;
  final String unit;

  /// ↳ 하위 항목 (회색)
  final bool sub;
  final String? keyName;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTypography.bodyMdM.copyWith(
      color: sub ? AppColors.foregroundTertiary : AppColors.foregroundPrimary,
    );
    final valueStyle = sub
        ? AppTypography.bodyMdM.copyWith(color: AppColors.foregroundTertiary)
        : AppTypography.bodyLgM.copyWith(color: AppColors.foregroundPrimary);
    final unitStyle = sub
        ? AppTypography.bodyMdR.copyWith(color: AppColors.foregroundTertiary)
        : AppTypography.bodyLgR.copyWith(color: AppColors.foregroundTertiary);

    return SizedBox(
      height: 25,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (sub) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 2.5),
              child: SvgPicture.asset(
                'assets/meal/arrow_bottom_right.svg',
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing15),
          ],
          Expanded(child: Text(label, style: labelStyle)),
          Text(
            value == null ? '-' : formatNutrient(value!),
            key: keyName == null ? null : ValueKey(keyName),
            style: valueStyle,
          ),
          const SizedBox(width: AppSpacing.spacing1),
          Text(unit, style: unitStyle),
        ],
      ),
    );
  }
}

class _NutrientCard extends StatelessWidget {
  const _NutrientCard({
    required this.main,
    this.subs = const [],
    this.last = false,
  });

  final Widget main;
  final List<Widget> subs;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: last ? 0 : AppSpacing.spacing2),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing3,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralsSurface,
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: Column(
        children: [
          main,
          for (final sub in subs) ...[
            const SizedBox(height: AppSpacing.spacing2),
            sub,
          ],
        ],
      ),
    );
  }
}

/// 탄·단·지 열량 비율 막대 + 범례
class _MacroRatioBar extends StatelessWidget {
  const _MacroRatioBar({required this.entry});

  final MealEntry entry;

  @override
  Widget build(BuildContext context) {
    // 열량 기준 비율 (탄수화물·단백질 4kcal/g, 지방 9kcal/g)
    final parts = [
      (label: '탄수화물', grams: entry.carbs, kcal: entry.carbs * 4, color: AppColors.dataCarb),
      (label: '단백질', grams: entry.protein, kcal: entry.protein * 4, color: AppColors.dataProtein),
      (label: '지방', grams: entry.fat, kcal: entry.fat * 9, color: AppColors.dataFat),
    ];
    final total = parts.fold<double>(0, (sum, p) => sum + p.kcal);
    final percents = [
      for (final p in parts) total == 0 ? 0 : (p.kcal / total * 100).round(),
    ];
    final barStyle = AppTypography.labelBadge.copyWith(
      color: AppColors.foregroundOnAccent,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          child: Container(
            height: 32,
            color: AppColors.neutralsSurface,
            child: Row(
              children: [
                for (final (i, p) in parts.indexed)
                  if (percents[i] > 0)
                    Expanded(
                      flex: percents[i],
                      child: Container(
                        color: p.color,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing2,
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            children: [
                              Text('${percents[i]}', style: barStyle),
                              Opacity(
                                opacity: 0.7,
                                child: Text('%', style: barStyle),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing2),
        Wrap(
          spacing: AppSpacing.spacing6,
          runSpacing: AppSpacing.spacing1,
          children: [
            for (final p in parts)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: p.color,
                      borderRadius: BorderRadius.circular(AppRadius.radiusXs),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing1),
                  Text(
                    p.label,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamilySans,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 15 / 11,
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.spacing1),
                  Text(
                    '${formatNutrient(p.grams)}g',
                    style: AppTypography.bodySmM.copyWith(
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
