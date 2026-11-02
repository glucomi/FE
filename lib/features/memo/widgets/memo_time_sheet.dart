import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/widgets/ruler_picker.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

/// 시간 선택 (COM-POP-03). 선택 완료를 누르면 고른 시간, 그냥 닫으면 null
Future<TimeOfDay?> showMemoTimeSheet(
  BuildContext context, {
  required TimeOfDay selected,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: (context) => MemoTimeSheet(selected: selected),
  );
}

/// 오전/오후 · 시(1~12) · 분(0~59) 휠
class MemoTimeSheet extends StatefulWidget {
  const MemoTimeSheet({super.key, required this.selected});

  final TimeOfDay selected;

  @override
  State<MemoTimeSheet> createState() => _MemoTimeSheetState();
}

class _MemoTimeSheetState extends State<MemoTimeSheet> {
  static const double _itemExtent = 38;
  static const int _visibleItems = 5;

  static const _periods = ['오전', '오후'];
  static final _hours = [for (var h = 1; h <= 12; h++) '$h'];
  static final _minutes = [for (var m = 0; m < 60; m++) '$m'];

  late int _period = widget.selected.hour < 12 ? 0 : 1;
  late int _hourIndex =
      (widget.selected.hourOfPeriod == 0 ? 12 : widget.selected.hourOfPeriod) -
      1;
  late int _minute = widget.selected.minute;

  TimeOfDay get _value {
    final hour12 = _hourIndex + 1; // 1~12
    final hour = (hour12 % 12) + (_period == 1 ? 12 : 0);
    return TimeOfDay(hour: hour, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: _itemExtent * _visibleItems,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.neutralsSurface,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Wheel(
                      key: const ValueKey('memo-time-period'),
                      width: 64,
                      labels: _periods,
                      initial: _period,
                      itemExtent: _itemExtent,
                      onChanged: (i) => setState(() => _period = i),
                    ),
                    const SizedBox(width: AppSpacing.spacing6),
                    _Wheel(
                      key: const ValueKey('memo-time-hour'),
                      width: 48,
                      labels: _hours,
                      initial: _hourIndex,
                      itemExtent: _itemExtent,
                      onChanged: (i) => setState(() => _hourIndex = i),
                    ),
                    const SizedBox(width: AppSpacing.spacing6),
                    _Wheel(
                      key: const ValueKey('memo-time-minute'),
                      width: 48,
                      labels: _minutes,
                      initial: _minute,
                      itemExtent: _itemExtent,
                      onChanged: (i) => setState(() => _minute = i),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          AppButton(
            key: const ValueKey('memo-time-confirm'),
            label: '선택 완료',
            onPressed: () => Navigator.of(context).pop(_value),
          ),
        ],
      ),
    );
  }
}

class _Wheel extends StatefulWidget {
  const _Wheel({
    super.key,
    required this.width,
    required this.labels,
    required this.initial,
    required this.itemExtent,
    required this.onChanged,
  });

  final double width;
  final List<String> labels;
  final int initial;
  final double itemExtent;
  final ValueChanged<int> onChanged;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.initial);
  late int _selected = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle _style(int distance) {
    if (distance == 0) {
      return AppTypography.bodyLgM.copyWith(color: AppColors.foregroundPrimary);
    }
    return AppTypography.bodyLgR.copyWith(
      color: distance == 1
          ? AppColors.foregroundQuaternary
          : AppColors.neutralsMuted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: ScrollConfiguration(
        behavior: pickerScrollBehavior(context),
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: widget.itemExtent,
          diameterRatio: 100,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            setState(() => _selected = index);
            widget.onChanged(index);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: widget.labels.length,
            builder: (context, index) => Center(
              child: Text(
                widget.labels[index],
                style: _style((index - _selected).abs()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
