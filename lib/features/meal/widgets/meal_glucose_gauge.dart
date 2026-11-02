import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_models.dart';

/// 예상 혈당 변화 게이지 (MO-MEAL-030 ②): 3분할 원호 + 등급 + 예상 변화량
class MealGlucoseGauge extends StatelessWidget {
  const MealGlucoseGauge({super.key, required this.delta});

  /// 예상 혈당 변화량 (mg/dL)
  final double delta;

  static const double _diameter = 170.6;
  static const double _height = 134;

  @override
  Widget build(BuildContext context) {
    final grade = GlucoseGrade.of(delta);
    final sign = delta >= 0 ? '+' : '';

    return Semantics(
      label: '예상 혈당 변화 ${grade.label}등급, $sign${delta.round()} mg/dL',
      excludeSemantics: true,
      child: SizedBox(
        height: _height,
        width: double.infinity,
        child: ClipRect(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              CustomPaint(
                size: const Size(_diameter, _diameter),
                painter: _GaugePainter(fill: grade.fill, color: grade.color),
              ),
              Positioned(
                top: 44.87,
                child: Text(
                  grade.label,
                  key: const ValueKey('meal-glucose-grade'),
                  style: AppTypography.displayLg.copyWith(color: grade.color),
                ),
              ),
              Positioned(
                top: 97,
                child: Column(
                  children: [
                    Text(
                      '예상 변화량',
                      style: AppTypography.bodyMdM.copyWith(
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing05),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$sign${delta.round()}',
                          key: const ValueKey('meal-glucose-delta'),
                          style: AppTypography.bodySmM.copyWith(
                            color: grade.color,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spacing05),
                        Text(
                          'mg/dL',
                          style: AppTypography.bodySmR.copyWith(
                            color: AppColors.foregroundTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.fill, required this.color});

  final double fill;
  final Color color;

  static const double _stroke = 8;

  /// 왼쪽 아래(135°)에서 시작해 시계방향으로 270°, 3구간
  static const double _start = 135 * math.pi / 180;
  static const double _sweep = 270 * math.pi / 180;
  static const double _gap = 8 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _stroke / 2,
      _stroke / 2,
      size.width - _stroke,
      size.height - _stroke,
    );
    Paint paintFor(Color c) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;

    final track = paintFor(AppColors.neutralsSubtle);
    final active = paintFor(color);
    final segment = (_sweep - _gap * 2) / 3;
    final filledTo = _start + _sweep * fill.clamp(0.0, 1.0);

    for (var i = 0; i < 3; i++) {
      final from = _start + (segment + _gap) * i;
      final to = from + segment;
      canvas.drawArc(rect, from, segment, false, track);
      if (filledTo > from) {
        final end = math.min(to, filledTo);
        canvas.drawArc(rect, from, end - from, false, active);
      }
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.fill != fill || old.color != color;
}
