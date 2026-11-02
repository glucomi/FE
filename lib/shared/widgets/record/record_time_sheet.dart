import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/widgets/ruler_picker.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

/// 시간 선택 (COM-POP-03). 선택 완료를 누르면 고른 시간, 그냥 닫으면 null
/// (기록 화면 공통: 복약 · 인슐린 등)
Future<TimeOfDay?> showRecordTimeSheet(
  BuildContext context, {
  required TimeOfDay selected,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: (context) => RecordTimeSheet(selected: selected),
  );
}

/// 오전/오후 · 시 · 분 휠
class RecordTimeSheet extends StatefulWidget {
  const RecordTimeSheet({super.key, required this.selected});

  final TimeOfDay selected;

  @override
  State<RecordTimeSheet> createState() => _RecordTimeSheetState();
}

class _RecordTimeSheetState extends State<RecordTimeSheet> {
  static const _periods = ['오전', '오후'];
  static final _hours = [for (var h = 1; h <= 12; h++) '$h'];
  static final _minutes = [for (var m = 0; m < 60; m++) '$m'];

  late int _period = widget.selected.hour >= 12 ? 1 : 0;

  /// 0 = 1시 … 11 = 12시
  late int _hour = (widget.selected.hourOfPeriod == 0 ? 12 : widget.selected.hourOfPeriod) - 1;
  late int _minute = widget.selected.minute;

  TimeOfDay get _value {
    final h12 = _hour + 1; // 1~12
    final hour = (h12 % 12) + (_period == 1 ? 12 : 0);
    return TimeOfDay(hour: hour, minute: _minute);
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      bottomPadding: AppSpacing.spacing2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 197,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 275,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.neutralsSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Wheel(
                      key: const ValueKey('record-time-period'),
                      labels: _periods,
                      initial: _period,
                      onChanged: (i) => setState(() => _period = i),
                    ),
                    const SizedBox(width: AppSpacing.spacing4),
                    _Wheel(
                      key: const ValueKey('record-time-hour'),
                      labels: _hours,
                      initial: _hour,
                      onChanged: (i) => setState(() => _hour = i),
                    ),
                    const SizedBox(width: AppSpacing.spacing4),
                    _Wheel(
                      key: const ValueKey('record-time-minute'),
                      labels: _minutes,
                      initial: _minute,
                      onChanged: (i) => setState(() => _minute = i),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          AppButton(
            key: const ValueKey('record-time-done'),
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
    required this.labels,
    required this.initial,
    required this.onChanged,
  });

  final List<String> labels;
  final int initial;
  final ValueChanged<int> onChanged;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  static const double _itemExtent = 28;

  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.initial);
  late int _selected = widget.initial;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TextStyle _style(int distance) => switch (distance) {
    0 => AppTypography.bodyLgM.copyWith(color: AppColors.foregroundPrimary),
    1 => AppTypography.bodyLgR.copyWith(color: AppColors.foregroundQuaternary),
    _ => AppTypography.bodyMdR.copyWith(color: AppColors.neutralsEmphasis),
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      child: ScrollConfiguration(
        behavior: pickerScrollBehavior(context),
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: _itemExtent,
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
