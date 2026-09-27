import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 날짜별 혈당 점수 표시 상태 (home/calendar/mark)
enum CalendarMarkState {
  none,
  good,
  warning,
  danger;

  /// 점수 구간 (추후 서버 기준으로 교체)
  static CalendarMarkState fromScore(int? score) {
    if (score == null) return none;
    if (score >= 65) return good;
    if (score >= 50) return warning;
    return danger;
  }

  Color get textColor => switch (this) {
    none => AppColors.foregroundQuaternary,
    good => AppColors.accentsSuccess,
    warning => AppColors.accentsWarning,
    danger => AppColors.accentsDanger,
  };
}

/// 24x24 점수 표시 (원 또는 별 모양 배경 + 점수)
class CalendarDayMark extends StatelessWidget {
  const CalendarDayMark({super.key, this.score});

  final int? score;

  static const double size = 24;

  // 별 모양은 28.07도 기울어져 있고 중심이 살짝 아래에 있음 (Figma 좌표 기준)
  static const Offset _burstCenter = Offset(11.93, 13.04);
  static const double _burstAngle = 28.07 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    final state = CalendarMarkState.fromScore(score);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          switch (state) {
            CalendarMarkState.none => const _Circle(AppColors.neutralsSurface),
            CalendarMarkState.good => const _Circle(AppColors.tintSuccess),
            CalendarMarkState.warning => const _Burst(
              asset: 'assets/home/calendar_mark_warning.svg',
              boxSize: Size(28.583, 27.759),
              // Figma inset 2.43% 2.88% 4.89% 3.52%
              padding: EdgeInsets.fromLTRB(1.006, 0.675, 0.823, 1.357),
            ),
            CalendarMarkState.danger => const _Burst(
              asset: 'assets/home/calendar_mark_danger.svg',
              boxSize: Size(30.543, 28.058),
            ),
          },
          Positioned(
            left: 0,
            right: 0,
            top: 4,
            child: Text(
              score?.toString() ?? '-',
              textAlign: TextAlign.center,
              style: AppTypography.labelNav.copyWith(color: state.textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

class _Burst extends StatelessWidget {
  const _Burst({
    required this.asset,
    required this.boxSize,
    this.padding = EdgeInsets.zero,
  });

  final String asset;
  final Size boxSize;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    const center = CalendarDayMark._burstCenter;
    return Positioned(
      left: center.dx - boxSize.width / 2,
      top: center.dy - boxSize.height / 2,
      width: boxSize.width,
      height: boxSize.height,
      child: Transform.rotate(
        angle: CalendarDayMark._burstAngle,
        child: Padding(
          padding: padding,
          child: SvgPicture.asset(asset, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

/// 날짜 한 칸 (home/calendar/day): 날짜 + 점수 표시, 높이 48
class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    super.key,
    required this.label,
    required this.labelStyle,
    this.score,
    this.dimmed = false,
    this.onTap,
  });

  final String label;
  final TextStyle labelStyle;
  final int? score;

  /// 이번 달이 아닌 날짜 (opacity 30%)
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget cell = SizedBox(
      height: 48,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 18,
            child: Center(child: Text(label, style: labelStyle)),
          ),
          const SizedBox(height: AppSpacing.spacing1),
          CalendarDayMark(score: score),
        ],
      ),
    );
    if (dimmed) cell = Opacity(opacity: 0.3, child: cell);
    if (onTap == null) return cell;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: cell,
    );
  }
}
