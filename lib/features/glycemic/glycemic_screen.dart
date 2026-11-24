import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/shared/widgets/app_confirm_dialog.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';

/// 혈당 반응 화면에 보여줄 식사 한 끼
class GlycemicMeal {
  const GlycemicMeal({
    required this.time,
    required this.foods,
    this.carbs,
    this.protein,
    this.fat,
    this.photos = const [],
  });

  /// 이 화면에서 바로 기록한 식사 (음식별 영양 정보가 있음)
  factory GlycemicMeal.fromRecord(MealRecord record) => GlycemicMeal(
    time: record.time,
    foods: [for (final e in record.entries) (name: e.food.name, kcal: e.kcal)],
    carbs: record.entries.fold<double>(0, (s, e) => s + e.carbs),
    protein: record.entries.fold<double>(0, (s, e) => s + e.protein),
    fat: record.entries.fold<double>(0, (s, e) => s + e.fat),
    photos: record.photos,
  );

  /// 홈 API 요약만 있는 식사 (대표 음식명·총 칼로리·탄수화물)
  factory GlycemicMeal.fromSummary({
    required DateTime time,
    required String title,
    double? kcal,
    double? carbs,
  }) => GlycemicMeal(
    time: time,
    foods: [(name: title, kcal: kcal ?? 0)],
    carbs: carbs,
  );

  final DateTime time;
  final List<({String name, double kcal})> foods;
  final double? carbs;
  final double? protein;
  final double? fat;
  final List<MealPhoto> photos;

  double get kcal => foods.fold(0, (s, f) => s + f.kcal);
}

/// 식후 반응 계산 (식전 · 식후 최고 · 2시간 후)
abstract final class GlycemicPolicy {
  static const Duration window = Duration(hours: 2);

  /// 식전 값으로 인정하는 범위 (식사 시각 전 30분)
  static const Duration beforeRange = Duration(minutes: 30);

  /// 2시간 후 값으로 인정하는 오차 (±15분)
  static const Duration afterTolerance = Duration(minutes: 15);

  static int? before(List<CgmPoint> points, DateTime meal) {
    CgmPoint? best;
    for (final p in points) {
      if (p.time.isAfter(meal) || meal.difference(p.time) > beforeRange) {
        continue;
      }
      if (best == null || p.time.isAfter(best.time)) best = p;
    }
    return best?.value.round();
  }

  static int? peak(List<CgmPoint> points, DateTime meal, DateTime now) {
    final end = meal.add(window);
    double? max;
    for (final p in points) {
      if (!p.time.isAfter(meal) || p.time.isAfter(end) || p.time.isAfter(now)) {
        continue;
      }
      if (max == null || p.value > max) max = p.value;
    }
    return max?.round();
  }

  static int? after2h(List<CgmPoint> points, DateTime meal, DateTime now) {
    final target = meal.add(window);
    if (now.isBefore(target)) return null;
    CgmPoint? best;
    for (final p in points) {
      final diff = p.time.difference(target).abs();
      if (diff > afterTolerance) continue;
      if (best == null || diff < best.time.difference(target).abs()) best = p;
    }
    return best?.value.round();
  }

  /// '1시간 32분' / '32분' — 2시간이 지났으면 null
  static String? remaining(DateTime meal, DateTime now) {
    final left = meal.add(window).difference(now);
    if (left <= Duration.zero) return null;
    final minutes = (left.inSeconds / 60).ceil();
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m분';
    return m == 0 ? '$h시간' : '$h시간 $m분';
  }
}

/// MO-GLYCEMIC-010 혈당 반응 (음식 기록)
///
/// 진입: MO-MEAL-040 저장하기 / AI 음식 촬영 자동 등록 / 홈 오늘의 기록 식단 카드
/// 정책서에 기능설명이 아직 없어 와이어프레임 (a) 2시간 전 · (b) 2시간 후 기준으로 구현
class GlycemicScreen extends StatelessWidget {
  const GlycemicScreen({
    super.key,
    required this.meal,
    this.points = const [],
    this.now,
    this.aiRecorded = false,
    this.onDelete,
    this.onEdit,
  });

  final GlycemicMeal meal;

  /// 그날 CGM 측정값 (식전·식후 최고·2시간 후 계산)
  final List<CgmPoint> points;
  final DateTime? now;

  /// AI 음식 촬영으로 자동 등록된 식사
  final bool aiRecorded;

  /// 삭제하기 — 성공하면 true. 없으면 준비 중 안내
  final Future<bool> Function()? onDelete;

  /// 수정하기 — 없으면 준비 중 안내
  final VoidCallback? onEdit;

  Future<void> _delete(BuildContext context) async {
    final delete = onDelete;
    if (delete == null) {
      showAppToast(context, '식사 기록 삭제는 준비 중입니다.');
      return;
    }
    if (!await showDeleteConfirmDialog(context)) return;
    if (!await delete()) return;
    if (context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = now ?? DateTime.now();
    final left = GlycemicPolicy.remaining(meal.time, current);

    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
          color: AppColors.neutralsBackground,
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const ValueKey('glycemic-delete'),
                  onPressed: () => _delete(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.foregroundPrimary,
                    side: const BorderSide(color: AppColors.borderStrong),
                  ),
                  child: const Text('삭제하기'),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing3),
              Expanded(
                child: FilledButton(
                  key: const ValueKey('glycemic-edit'),
                  onPressed:
                      onEdit ??
                      () => showAppToast(context, '식사 기록 수정은 준비 중입니다.'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.accentsBrand,
                  ),
                  child: const Text('수정하기'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeaderBar(
              title: '음식 기록',
              iconLeft: GestureDetector(
                key: const ValueKey('glycemic-close'),
                onTap: () => Navigator.of(context).maybePop(),
                child: const Icon(Icons.close, size: 24),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.spacing6),
                children: [
                  _DateRow(time: meal.time, aiRecorded: aiRecorded),
                  _Card(child: _Prediction(remaining: left)),
                  _Card(
                    child: _ReactionValues(
                      before: GlycemicPolicy.before(points, meal.time),
                      peak: GlycemicPolicy.peak(points, meal.time, current),
                      after: GlycemicPolicy.after2h(points, meal.time, current),
                    ),
                  ),
                  if (meal.photos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacing3),
                      child: _PhotoPager(
                        photos: meal.photos,
                        foodNames: [for (final f in meal.foods) f.name],
                      ),
                    ),
                  _Nutrition(meal: meal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.spacing3,
        AppSpacing.spacing3,
        AppSpacing.spacing3,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: AppColors.neutralsBackground,
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: child,
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.time, required this.aiRecorded});

  final DateTime time;
  final bool aiRecorded;

  @override
  Widget build(BuildContext context) {
    String two(int v) => v.toString().padLeft(2, '0');
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final meta = AppTypography.bodySmR.copyWith(
      color: AppColors.foregroundSecondary,
    );
    return Container(
      color: AppColors.neutralsBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing3,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing2,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.neutralsSubtle,
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            ),
            child: Text(
              aiRecorded ? 'AI 음식' : '기록일',
              style: AppTypography.labelBadge.copyWith(
                color: AppColors.foregroundTertiary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.spacing3),
          const Icon(
            Icons.calendar_today_outlined,
            size: 14,
            color: AppColors.foregroundTertiary,
          ),
          const SizedBox(width: AppSpacing.spacing1),
          Text(
            '${time.year}년 ${two(time.month)}월 ${two(time.day)}일',
            style: meta,
          ),
          const SizedBox(width: AppSpacing.spacing3),
          const Icon(
            Icons.access_time,
            size: 14,
            color: AppColors.foregroundTertiary,
          ),
          const SizedBox(width: AppSpacing.spacing1),
          Text(
            '${time.hour < 12 ? '오전' : '오후'} ${two(hour)}:${two(time.minute)}',
            style: meta,
          ),
        ],
      ),
    );
  }
}

/// ③ 예상 혈당 변화 · ④ 실제 반응 안내
class _Prediction extends StatelessWidget {
  const _Prediction({required this.remaining});

  final String? remaining;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing3,
            vertical: AppSpacing.spacing1,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutralsSubtle,
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          ),
          child: Text(
            '예상 혈당 변화',
            style: AppTypography.labelBadge.copyWith(
              color: AppColors.foregroundSecondary,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        // 예측 등급·변화량 API 가 없어 빈 값으로 표시 (docs/be-requests.md)
        SizedBox(
          width: 120,
          height: 90,
          child: CustomPaint(
            painter: _GaugePainter(),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '-',
                    style: AppTypography.displayMd.copyWith(
                      color: AppColors.foregroundQuaternary,
                    ),
                  ),
                  Text(
                    '예상 변화량',
                    style: AppTypography.labelBadge.copyWith(
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                  Text(
                    '-- mg/dL',
                    style: AppTypography.labelBadge.copyWith(
                      color: AppColors.foregroundQuaternary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing4),
        Text(
          remaining != null
              ? '실제 반응은 $remaining 후에 확인해보세요!'
              : '식후 2시간 실제 반응이에요',
          style: AppTypography.bodyMdM.copyWith(
            color: AppColors.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing2),
        Text(
          'ⓘ 따당의 데이터를 기반으로 예측한 변화예요',
          style: AppTypography.labelBadge.copyWith(
            color: AppColors.foregroundQuaternary,
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.neutralsMuted;
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height * 0.62),
      radius: size.width / 2 - 4,
    );
    canvas.drawArc(rect, math.pi * 0.8, math.pi * 1.4, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// ⑤ 식전 · 식후 최고 · 2시간 후
class _ReactionValues extends StatelessWidget {
  const _ReactionValues({this.before, this.peak, this.after});

  final int? before;
  final int? peak;
  final int? after;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, int? value) => Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelBadge.copyWith(
              color: AppColors.foregroundTertiary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing1),
          Text(
            value?.toString() ?? '--',
            style: AppTypography.headingH2.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
          Text(
            'mg/dL',
            style: AppTypography.labelBadge.copyWith(
              color: AppColors.foregroundQuaternary,
            ),
          ),
        ],
      ),
    );
    final divider = Container(
      width: 1,
      height: 36,
      color: AppColors.borderDefault,
    );
    return Row(
      children: [
        cell('식전', before),
        divider,
        cell('식후 최고', peak),
        divider,
        cell('2시간 후', after),
      ],
    );
  }
}

/// ⑥ 사진 (1/N) + 음식칩
class _PhotoPager extends StatefulWidget {
  const _PhotoPager({required this.photos, required this.foodNames});

  final List<MealPhoto> photos;
  final List<String> foodNames;

  @override
  State<_PhotoPager> createState() => _PhotoPagerState();
}

class _PhotoPagerState extends State<_PhotoPager> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) {
                final photo = widget.photos[i];
                return LayoutBuilder(
                  builder: (context, c) => Stack(
                    children: [
                      Positioned.fill(
                        child: Image.memory(photo.bytes, fit: BoxFit.cover),
                      ),
                      if (photo.label != null)
                        FoodChipOverlay(
                          label: photo.label!,
                          center: photo.center,
                          size: c.biggest,
                        ),
                    ],
                  ),
                );
              },
            ),
            Positioned(
              left: AppSpacing.spacing3,
              top: AppSpacing.spacing3,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing2,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                ),
                child: Text(
                  '${_index + 1}/${widget.photos.length}',
                  style: AppTypography.labelBadge.copyWith(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 사진 위 음식칩 — AI 로컬라이저가 준 음식 중심 좌표(비율)에 띄움, 없으면 가운데
class FoodChipOverlay extends StatelessWidget {
  const FoodChipOverlay({
    super.key,
    required this.label,
    required this.size,
    this.center,
  });

  final String label;
  final Size size;
  final Offset? center;

  @override
  Widget build(BuildContext context) {
    final c = center ?? const Offset(0.5, 0.5);
    return Positioned(
      left: c.dx * size.width,
      top: c.dy * size.height,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing2,
            vertical: AppSpacing.spacing1,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
          ),
          child: Text(
            label,
            style: AppTypography.labelBadge.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// ⑦ 총 열량 · 탄단지 비율 · 음식별 칼로리
class _Nutrition extends StatelessWidget {
  const _Nutrition({required this.meal});

  final GlycemicMeal meal;

  @override
  Widget build(BuildContext context) {
    final carbs = meal.carbs;
    final protein = meal.protein;
    final fat = meal.fat;
    // 칼로리 기준 비율 (탄·단 4kcal, 지 9kcal)
    final parts = [
      (label: '탄수화물', g: carbs, kcal: (carbs ?? 0) * 4, color: AppColors.statusWarning),
      (label: '단백질', g: protein, kcal: (protein ?? 0) * 4, color: AppColors.blue400),
      (label: '지방', g: fat, kcal: (fat ?? 0) * 9, color: AppColors.purple400),
    ];
    final total = parts.fold<double>(0, (s, p) => s + p.kcal);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.spacing3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                '총 열량',
                style: AppTypography.bodyMdM.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${meal.kcal.round()} kcal',
                style: AppTypography.bodyMdM.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            child: SizedBox(
              height: 20,
              child: total == 0
                  ? const ColoredBox(color: AppColors.neutralsMuted)
                  : Row(
                      children: [
                        for (final p in parts)
                          if (p.kcal > 0)
                            Expanded(
                              flex: (p.kcal / total * 1000).round().clamp(1, 1000).toInt(),
                              child: ColoredBox(
                                color: p.color,
                                child: Center(
                                  child: Text(
                                    '${(p.kcal / total * 100).round()}%',
                                    style: AppTypography.labelBadge.copyWith(
                                      color: Colors.white,
                                    ),
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
            spacing: AppSpacing.spacing3,
            children: [
              for (final p in parts)
                Text(
                  '■ ${p.label} ${p.g == null ? '--' : '${formatMealNumber(p.g!)}g'}',
                  style: AppTypography.labelBadge.copyWith(color: p.color),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing3),
          Container(
            padding: const EdgeInsets.all(AppSpacing.spacing3),
            decoration: BoxDecoration(
              color: AppColors.neutralsBackground,
              borderRadius: BorderRadius.circular(AppRadius.radiusLg),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: Column(
              children: [
                for (final f in meal.foods)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '·  ${f.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmR.copyWith(
                              color: AppColors.foregroundSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spacing2),
                        Text(
                          '${f.kcal.round()} kcal',
                          style: AppTypography.bodySmR.copyWith(
                            color: AppColors.foregroundSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
