import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 눈금자 형태로 값을 고르는 피커 (키: 세로, 몸무게: 가로)
///
/// 눈금 1칸 = [step], 눈금 간격 8px, [majorEvery]칸마다 긴 눈금.
class RulerPicker extends StatefulWidget {
  const RulerPicker({
    super.key,
    required this.axis,
    required this.min,
    required this.max,
    required this.step,
    required this.value,
    required this.onChanged,
    this.majorEvery = 10,
  });

  final Axis axis;
  final double min;
  final double max;
  final double step;
  final double value;
  final ValueChanged<double> onChanged;
  final int majorEvery;

  static const double tickSpacing = 8;
  static const double rulerThickness = 40;
  static const double minorTickLength = 24;
  static const double indicatorLength = 64;
  static const double indicatorThickness = 3;

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  late final ScrollController _controller;
  late int _index;

  int get _tickCount => ((widget.max - widget.min) / widget.step).round() + 1;

  bool get _vertical => widget.axis == Axis.vertical;

  @override
  void initState() {
    super.initState();
    _index = ((widget.value - widget.min) / widget.step)
        .round()
        .clamp(0, _tickCount - 1);
    _controller = ScrollController(
      initialScrollOffset: _index * RulerPicker.tickSpacing,
    )..addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final next = (_controller.offset / RulerPicker.tickSpacing)
        .round()
        .clamp(0, _tickCount - 1);
    if (next == _index) return;
    _index = next;
    widget.onChanged(widget.min + next * widget.step);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final extent = _vertical ? constraints.maxHeight : constraints.maxWidth;
        final edge = extent / 2 - RulerPicker.tickSpacing / 2;

        return ScrollConfiguration(
          behavior: pickerScrollBehavior(context),
          child: ListView.builder(
            controller: _controller,
            scrollDirection: widget.axis,
            // 세로 눈금자는 위로 올릴수록 값이 커지도록 뒤집음
            reverse: _vertical,
            physics: const _TickSnapPhysics(
              tickExtent: RulerPicker.tickSpacing,
              parent: ClampingScrollPhysics(),
            ),
            padding: _vertical
                ? EdgeInsets.symmetric(vertical: edge)
                : EdgeInsets.symmetric(horizontal: edge),
            itemExtent: RulerPicker.tickSpacing,
            itemCount: _tickCount,
            itemBuilder: (context, index) {
              final major = index % widget.majorEvery == 0;
              final length = major
                  ? RulerPicker.rulerThickness
                  : RulerPicker.minorTickLength;
              final color = major
                  ? AppColors.neutralsEmphasis
                  : AppColors.neutralsMuted;

              return Align(
                alignment: _vertical
                    ? Alignment.centerLeft
                    : Alignment.bottomCenter,
                child: Container(
                  width: _vertical ? length : 1,
                  height: _vertical ? 1 : length,
                  color: color,
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// 마우스 드래그로도 움직이고 스크롤바는 숨김 (웹 미리보기 대응)
ScrollBehavior pickerScrollBehavior(BuildContext context) =>
    ScrollConfiguration.of(context).copyWith(
      scrollbars: false,
      dragDevices: PointerDeviceKind.values.toSet(),
    );

/// 스크롤이 멈추면 가장 가까운 눈금에 맞춰 정렬
class _TickSnapPhysics extends ScrollPhysics {
  const _TickSnapPhysics({required this.tickExtent, super.parent});

  final double tickExtent;

  @override
  _TickSnapPhysics applyTo(ScrollPhysics? ancestor) =>
      _TickSnapPhysics(tickExtent: tickExtent, parent: buildParent(ancestor));

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    if ((velocity <= 0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0 && position.pixels >= position.maxScrollExtent)) {
      return super.createBallisticSimulation(position, velocity);
    }

    final tolerance = toleranceFor(position);
    final simulation = super.createBallisticSimulation(position, velocity);
    final projected = simulation?.x(double.infinity) ?? position.pixels;
    final target = ((projected / tickExtent).round() * tickExtent).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    if ((target - position.pixels).abs() < tolerance.distance) return null;

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }
}

/// 현재 선택 위치를 표시하는 브랜드 컬러 막대
class RulerIndicator extends StatelessWidget {
  const RulerIndicator({super.key, required this.axis});

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final vertical = axis == Axis.vertical;
    return Container(
      width: vertical ? RulerPicker.indicatorLength : RulerPicker.indicatorThickness,
      height: vertical ? RulerPicker.indicatorThickness : RulerPicker.indicatorLength,
      decoration: BoxDecoration(
        color: AppColors.accentsBrand,
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
    );
  }
}

/// 눈금자 양 끝을 흐리게 만드는 그라데이션
class RulerFade extends StatelessWidget {
  const RulerFade({super.key, required this.begin, required this.end});

  final Alignment begin;
  final Alignment end;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: begin,
            end: end,
            colors: [
              AppColors.neutralsBackground,
              AppColors.neutralsBackground.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

/// 큰 숫자 + 단위 (168 cm, 47.7 kg)
class RulerValueLabel extends StatelessWidget {
  const RulerValueLabel({super.key, required this.value, required this.unit});

  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: AppTypography.displayLg.copyWith(
            color: AppColors.foregroundPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing2),
        Text(
          unit,
          style: AppTypography.bodyMdR.copyWith(
            color: AppColors.foregroundQuaternary,
          ),
        ),
      ],
    );
  }
}
