import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/widgets/ruler_picker.dart';

/// 목표 혈당 범위 휠 피커 (최소 - 최대 mg/dL)
class RangeWheelPicker extends StatelessWidget {
  const RangeWheelPicker({
    super.key,
    required this.minValues,
    required this.maxValues,
    required this.minValue,
    required this.maxValue,
    required this.onMinChanged,
    required this.onMaxChanged,
    this.unit = 'mg/dL',
  });

  final List<int> minValues;
  final List<int> maxValues;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onMinChanged;
  final ValueChanged<int> onMaxChanged;
  final String unit;

  static const double itemExtent = 42;
  static const int visibleItems = 5;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemExtent * visibleItems,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 253,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.neutralsSurface,
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _WheelColumn(
                key: const ValueKey('target-min'),
                width: 44,
                values: minValues,
                value: minValue,
                onChanged: onMinChanged,
              ),
              const SizedBox(width: AppSpacing.spacing6),
              Text('-', style: _selectedStyle),
              const SizedBox(width: AppSpacing.spacing6),
              _WheelColumn(
                key: const ValueKey('target-max'),
                width: 52,
                values: maxValues,
                value: maxValue,
                onChanged: onMaxChanged,
              ),
              const SizedBox(width: AppSpacing.spacing6),
              Text(
                unit,
                style: AppTypography.headingH3.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final TextStyle _selectedStyle = AppTypography.displaySm.copyWith(
  color: AppColors.foregroundPrimary,
);

TextStyle _styleForDistance(int distance) {
  if (distance == 0) return _selectedStyle;
  if (distance == 1) {
    return const TextStyle(
      fontFamily: AppTypography.fontFamilySans,
      fontSize: 22,
      fontWeight: FontWeight.w400,
      color: AppColors.neutralsMuted,
    );
  }
  return const TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSize3xl,
    fontWeight: FontWeight.w400,
    color: AppColors.neutralsSubtle,
  );
}

class _WheelColumn extends StatefulWidget {
  const _WheelColumn({
    super.key,
    required this.width,
    required this.values,
    required this.value,
    required this.onChanged,
  });

  final double width;
  final List<int> values;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<_WheelColumn> {
  late final FixedExtentScrollController _controller;
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.values.indexOf(widget.value).clamp(0, widget.values.length - 1);
    _controller = FixedExtentScrollController(initialItem: _selected);
  }

  @override
  void didUpdateWidget(covariant _WheelColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = widget.values.indexOf(widget.value);
    if (index >= 0 && index != _selected) {
      _selected = index;
      // 반대쪽 휠에 밀려 바뀐 경우: 애니메이션 중간값으로 콜백이 연쇄되지 않게 바로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToItem(index);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: ScrollConfiguration(
        behavior: pickerScrollBehavior(context),
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: RangeWheelPicker.itemExtent,
          diameterRatio: 100,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() => _selected = index);
            widget.onChanged(widget.values[index]);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.values.length,
            builder: (context, index) => Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${widget.values[index]}',
                style: _styleForDistance((index - _selected).abs()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
