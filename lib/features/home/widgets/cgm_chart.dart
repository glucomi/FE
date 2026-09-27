import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/home_models.dart';

/// 홈 CGM 그래프
///
/// - 한 손가락 드래그: 좌우 이동
/// - 두 손가락 핀치: 확대/축소 (1~6시간)
/// - 탭: 가장 가까운 혈당값 선택 → 말풍선 표시
/// - 이동/확대 중에는 선택 해제
class CgmChart extends StatefulWidget {
  const CgmChart({
    super.key,
    required this.points,
    this.records = const [],
    this.targetMin = 70,
    this.targetMax = 140,
    this.now,
  });

  final List<CgmPoint> points;

  /// 그래프 위에 아이콘으로 표시할 기록
  final List<DailyRecord> records;
  final int targetMin;
  final int targetMax;

  /// 데이터가 없을 때 x축 기준 시각
  final DateTime? now;

  // Figma chart 크기 (326 x 184)
  static const double height = 184;
  static const double plotLeft = 28;
  static const double plotTop = 6.5;
  static const double plotBottom = 147.5;
  static const double axisBottom = 154;
  static const double minGlucose = 50;
  static const double maxGlucose = 200;
  static const double veryHigh = 180;

  static const double minVisibleHours = 1;
  static const double maxVisibleHours = 6;

  /// 처음 한 화면에 보여줄 시간 (그래프 테스트 화면과 동일하게 3시간)
  static const double defaultVisibleHours = 3;

  @override
  State<CgmChart> createState() => _CgmChartState();
}

class _CgmChartState extends State<CgmChart> {
  int? _selectedIndex;

  // 데이터 시작점에서 몇 시간 이동했는지
  double _offsetHours = 0;
  double _visibleHours = CgmChart.defaultVisibleHours;

  double _scaleStartVisibleHours = CgmChart.defaultVisibleHours;
  double _scaleFocalHour = 0;

  @override
  void initState() {
    super.initState();
    // 데이터가 없으면 Figma처럼 최근 5시간 눈금만 표시
    if (widget.points.isEmpty) _visibleHours = _emptyVisibleHours;
    // 처음에는 가장 최근 데이터가 보이도록
    _offsetHours = _maxOffset;
  }

  @override
  void didUpdateWidget(covariant CgmChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _selectedIndex = null;
      _visibleHours = widget.points.isEmpty
          ? _emptyVisibleHours
          : CgmChart.defaultVisibleHours;
      _offsetHours = _maxOffset;
    }
  }

  DateTime get _domainStart {
    if (widget.points.isNotEmpty) return widget.points.first.time;
    final now = widget.now ?? DateTime.now();
    final end = DateTime(now.year, now.month, now.day, now.hour + 1);
    return end.subtract(const Duration(hours: 5));
  }

  static const double _emptyVisibleHours = 5;

  double get _totalHours {
    if (widget.points.length < 2) return 0;
    return widget.points.last.time
            .difference(widget.points.first.time)
            .inMilliseconds /
        Duration.millisecondsPerHour;
  }

  double get _maxOffset => math.max(0, _totalHours - _visibleHours);

  _ChartGeometry _geometry(Size size) => _ChartGeometry(
    size: size,
    start: _domainStart.add(
      Duration(
        milliseconds: (_offsetHours * Duration.millisecondsPerHour).round(),
      ),
    ),
    visibleHours: _visibleHours,
  );

  void _select(Offset position, Size size) {
    if (widget.points.isEmpty) return;
    final geometry = _geometry(size);
    final touchX = position.dx.clamp(CgmChart.plotLeft, size.width);

    int? closest;
    var closestDistance = double.infinity;
    for (var i = 0; i < widget.points.length; i++) {
      final point = widget.points[i];
      if (!geometry.contains(point.time)) continue;
      final distance = (geometry.xForTime(point.time) - touchX).abs();
      if (distance < closestDistance) {
        closestDistance = distance;
        closest = i;
      }
    }
    if (closest == null) return;
    setState(() => _selectedIndex = closest);
  }

  void _onScaleStart(ScaleStartDetails details, Size size) {
    final plotWidth = size.width - CgmChart.plotLeft;
    if (plotWidth <= 0) return;
    _scaleStartVisibleHours = _visibleHours;
    final ratio = ((details.localFocalPoint.dx - CgmChart.plotLeft) / plotWidth)
        .clamp(0.0, 1.0);
    _scaleFocalHour = _offsetHours + ratio * _visibleHours;
  }

  void _onScaleUpdate(ScaleUpdateDetails details, Size size) {
    if (widget.points.length < 2) return;
    final plotWidth = size.width - CgmChart.plotLeft;
    if (plotWidth <= 0) return;

    // 두 손가락 → 확대/축소 (핀치 중심 시각을 고정)
    if (details.pointerCount >= 2) {
      final maxHours = math.min(
        CgmChart.maxVisibleHours,
        math.max(CgmChart.minVisibleHours, _totalHours),
      );
      final visible = (_scaleStartVisibleHours / details.scale)
          .clamp(CgmChart.minVisibleHours, maxHours)
          .toDouble();
      final ratio =
          ((details.localFocalPoint.dx - CgmChart.plotLeft) / plotWidth)
              .clamp(0.0, 1.0);
      final offset = (_scaleFocalHour - ratio * visible)
          .clamp(0.0, math.max(0.0, _totalHours - visible))
          .toDouble();
      setState(() {
        _visibleHours = visible;
        _offsetHours = offset;
        _selectedIndex = null;
      });
      return;
    }

    // 한 손가락 → 좌우 이동
    final deltaHours = -(details.focalPointDelta.dx / plotWidth) * _visibleHours;
    setState(() {
      _offsetHours = (_offsetHours + deltaHours).clamp(0.0, _maxOffset);
      _selectedIndex = null;
    });
  }

  double _valueAt(DateTime time) {
    final points = widget.points;
    if (points.isEmpty) return 0;
    if (!time.isAfter(points.first.time)) return points.first.value;
    for (var i = 1; i < points.length; i++) {
      final b = points[i];
      if (!time.isAfter(b.time)) {
        final a = points[i - 1];
        final span = b.time.difference(a.time).inMilliseconds;
        final t = span == 0 ? 0 : time.difference(a.time).inMilliseconds / span;
        return a.value + (b.value - a.value) * t;
      }
    }
    return points.last.value;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CgmChart.height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, CgmChart.height);
          final geometry = _geometry(size);
          final selected = _selectedIndex;

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => _select(details.localPosition, size),
            onScaleStart: (details) => _onScaleStart(details, size),
            onScaleUpdate: (details) => _onScaleUpdate(details, size),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: size,
                  painter: _CgmChartPainter(
                    points: widget.points,
                    geometry: geometry,
                    selectedIndex: selected,
                    targetMin: widget.targetMin.toDouble(),
                    targetMax: widget.targetMax.toDouble(),
                  ),
                ),
                if (widget.points.isEmpty)
                  const Positioned(
                    left: CgmChart.plotLeft,
                    right: 0,
                    top: 56,
                    child: _EmptyMessage(),
                  ),
                if (widget.points.isNotEmpty)
                  for (final record in widget.records)
                    if (geometry.contains(record.time) &&
                        !record.time.isAfter(widget.points.last.time))
                      Positioned(
                        left: geometry.xForTime(record.time) - 12,
                        top: _ChartGeometry.yForValue(_valueAt(record.time)) -
                            12,
                        child: IgnorePointer(child: _RecordMarker(record.type)),
                      ),
                if (selected != null &&
                    geometry.contains(widget.points[selected].time))
                  _Tooltip(
                    point: widget.points[selected],
                    previous: selected > 0 ? widget.points[selected - 1] : null,
                    color: _colorFor(
                      widget.points[selected].value,
                      widget.targetMin.toDouble(),
                      widget.targetMax.toDouble(),
                    ),
                    anchor: Offset(
                      geometry.xForTime(widget.points[selected].time),
                      _ChartGeometry.yForValue(widget.points[selected].value),
                    ),
                    chartWidth: size.width,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

Color _colorFor(double value, double targetMin, double targetMax) {
  if (value < targetMin || value > CgmChart.veryHigh) {
    return AppColors.statusError;
  }
  if (value > targetMax) return AppColors.statusWarning;
  return AppColors.accentsBrand;
}

/// 시간/값 → 화면 좌표 변환
class _ChartGeometry {
  const _ChartGeometry({
    required this.size,
    required this.start,
    required this.visibleHours,
  });

  final Size size;
  final DateTime start;
  final double visibleHours;

  DateTime get end => start.add(
    Duration(milliseconds: (visibleHours * Duration.millisecondsPerHour).round()),
  );

  double get plotWidth => size.width - CgmChart.plotLeft;

  bool contains(DateTime time) => !time.isBefore(start) && !time.isAfter(end);

  double xForTime(DateTime time) {
    final hours =
        time.difference(start).inMilliseconds / Duration.millisecondsPerHour;
    return CgmChart.plotLeft + hours / visibleHours * plotWidth;
  }

  static double yForValue(double value) {
    const range = CgmChart.maxGlucose - CgmChart.minGlucose;
    const height = CgmChart.plotBottom - CgmChart.plotTop;
    return CgmChart.plotTop + (CgmChart.maxGlucose - value) / range * height;
  }
}

class _CgmChartPainter extends CustomPainter {
  _CgmChartPainter({
    required this.points,
    required this.geometry,
    required this.selectedIndex,
    required this.targetMin,
    required this.targetMax,
  });

  final List<CgmPoint> points;
  final _ChartGeometry geometry;
  final int? selectedIndex;
  final double targetMin;
  final double targetMax;

  static const Color _grid = AppColors.gray200;

  @override
  void paint(Canvas canvas, Size size) {
    final left = CgmChart.plotLeft;
    final right = size.width;
    final top = CgmChart.plotTop;
    final bottom = CgmChart.plotBottom;
    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 1;

    // 목표 범위 영역 (오른쪽 끝은 흐리게)
    final bandTop = _ChartGeometry.yForValue(targetMax);
    final bandBottom = _ChartGeometry.yForValue(targetMin);
    final bandRect = Rect.fromLTRB(left, bandTop, right, bandBottom);
    canvas.drawRect(
      bandRect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.accentsBrand.withValues(alpha: 0.05),
            AppColors.accentsBrand.withValues(alpha: 0.05),
            AppColors.accentsBrand.withValues(alpha: 0),
          ],
          stops: const [0, 0.883, 1],
        ).createShader(bandRect),
    );

    // y축 눈금 + 가로 점선
    for (final value in const [200.0, 150.0, 100.0, 50.0]) {
      final y = _ChartGeometry.yForValue(value);
      _dashedLine(canvas, Offset(left, y), Offset(right, y), gridPaint);
      _text(
        canvas,
        value.toInt().toString(),
        Offset(0, y - 9),
        width: 24,
      );
    }

    // y축 세로선
    canvas.drawLine(
      Offset(left, top - 0.5),
      Offset(left, bottom),
      gridPaint,
    );

    // 정시마다 세로 점선 + 시각
    var hour = DateTime(
      geometry.start.year,
      geometry.start.month,
      geometry.start.day,
      geometry.start.hour,
    );
    if (hour.isBefore(geometry.start)) hour = hour.add(const Duration(hours: 1));
    while (!hour.isAfter(geometry.end)) {
      final x = geometry.xForTime(hour);
      if (x > left + 1) {
        _dashedLine(canvas, Offset(x, top), Offset(x, bottom), gridPaint);
      }
      final label = '${hour.hour.toString().padLeft(2, '0')}시';
      final painter = _layout(label);
      final labelX = (x - painter.width / 2).clamp(
        left - 4,
        right - painter.width,
      );
      painter.paint(canvas, Offset(labelX, CgmChart.axisBottom + 12));
      hour = hour.add(const Duration(hours: 1));
    }

    if (points.isEmpty) return;

    // 혈당 곡선 — 구간별 색 (저혈당·고혈당 빨강, 주의 주황, 정상 초록)
    final offsets = [
      for (final p in points)
        Offset(geometry.xForTime(p.time), _ChartGeometry.yForValue(p.value)),
    ];
    final path = _smoothPath(offsets);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(left, 0, right, CgmChart.axisBottom));

    void band(double fromValue, double toValue, Color color) {
      canvas.save();
      canvas.clipRect(
        Rect.fromLTRB(
          left,
          _ChartGeometry.yForValue(toValue),
          right,
          _ChartGeometry.yForValue(fromValue),
        ),
      );
      canvas.drawPath(path, line..color = color);
      canvas.restore();
    }

    band(-1000, targetMin, AppColors.statusError);
    band(targetMin, targetMax, AppColors.accentsBrand);
    band(targetMax, CgmChart.veryHigh, AppColors.statusWarning);
    band(CgmChart.veryHigh, 1000, AppColors.statusError);
    canvas.restore();

    // 선택된 점
    final index = selectedIndex;
    if (index != null && geometry.contains(points[index].time)) {
      final offset = offsets[index];
      final color = _colorFor(points[index].value, targetMin, targetMax);
      _dashedLine(
        canvas,
        Offset(offset.dx, top),
        Offset(offset.dx, bottom),
        Paint()
          ..color = color
          ..strokeWidth = 1.5,
        dash: 2,
        gap: 4,
      );
      canvas.drawCircle(offset, 8, Paint()..color = Colors.white);
      canvas.drawCircle(offset, 5.5, Paint()..color = color);
    }
  }

  TextPainter _layout(String text) => TextPainter(
    text: TextSpan(
      text: text,
      style: AppTypography.labelMeta.copyWith(
        color: AppColors.foregroundTertiary,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  void _text(Canvas canvas, String text, Offset offset, {double? width}) {
    final painter = _layout(text);
    painter.paint(canvas, offset);
  }

  void _dashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dash = 3,
    double gap = 3,
  }) {
    final diff = end - start;
    final total = diff.distance;
    if (total == 0) return;
    final direction = diff / total;
    var current = 0.0;
    while (current < total) {
      final segmentEnd = math.min(current + dash, total);
      canvas.drawLine(
        start + direction * current,
        start + direction * segmentEnd,
        paint,
      );
      current += dash + gap;
    }
  }

  Path _smoothPath(List<Offset> offsets) {
    final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    if (offsets.length == 1) return path;
    for (var i = 0; i < offsets.length - 1; i++) {
      final current = offsets[i];
      final next = offsets[i + 1];
      final middle = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, middle.dx, middle.dy);
    }
    final beforeLast = offsets[offsets.length - 2];
    path.quadraticBezierTo(
      beforeLast.dx,
      beforeLast.dy,
      offsets.last.dx,
      offsets.last.dy,
    );
    return path;
  }

  @override
  bool shouldRepaint(covariant _CgmChartPainter old) =>
      old.points != points ||
      old.selectedIndex != selectedIndex ||
      old.geometry.start != geometry.start ||
      old.geometry.visibleHours != geometry.visibleHours ||
      old.geometry.size != geometry.size ||
      old.targetMin != targetMin ||
      old.targetMax != targetMax;
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '기록이 없습니다',
          style: AppTypography.bodyMdM.copyWith(
            color: AppColors.foregroundSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing05),
        Text(
          '기록을 추가해주세요',
          style: AppTypography.bodySmR.copyWith(
            color: AppColors.foregroundTertiary,
          ),
        ),
      ],
    );
  }
}

/// 그래프 위 기록 아이콘 (흰 원 + 12px 아이콘)
class _RecordMarker extends StatelessWidget {
  const _RecordMarker(this.type);

  final DailyRecordType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.foregroundOnAccent,
        shape: BoxShape.circle,
        boxShadow: AppShadows.defaultShadow,
      ),
      child: SvgPicture.asset(
        type.iconAsset,
        width: 12,
        height: 12,
        colorFilter: const ColorFilter.mode(
          AppColors.foregroundSecondary,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}

/// 선택한 혈당값 말풍선
class _Tooltip extends StatelessWidget {
  const _Tooltip({
    required this.point,
    required this.previous,
    required this.color,
    required this.anchor,
    required this.chartWidth,
  });

  final CgmPoint point;
  final CgmPoint? previous;
  final Color color;
  final Offset anchor;
  final double chartWidth;

  static const double _width = 122;
  static const double _height = 58;

  @override
  Widget build(BuildContext context) {
    var arrow = '→';
    if (previous != null) {
      final diff = point.value - previous!.value;
      if (diff >= 5) {
        arrow = '↑';
      } else if (diff <= -5) {
        arrow = '↓';
      }
    }

    final left = (anchor.dx - _width / 2).clamp(
      CgmChart.plotLeft,
      math.max(CgmChart.plotLeft, chartWidth - _width),
    );
    var top = anchor.dy - _height - 14;
    if (top < 4) top = anchor.dy + 14;

    final hour = point.time.hour;
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final time =
        '${hour >= 12 ? '오후' : '오전'} ${displayHour.toString().padLeft(2, '0')}:'
        '${point.time.minute.toString().padLeft(2, '0')}';

    return Positioned(
      left: left.toDouble(),
      top: top,
      child: IgnorePointer(
        child: Container(
          width: _width,
          height: _height,
          padding: const EdgeInsets.fromLTRB(12, 7, 7, 7),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${point.value.round()} $arrow',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamilySans,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: AppColors.foregroundOnAccent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'mg/dl',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamilySans,
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    time,
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamilySans,
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add_rounded, size: 14, color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
