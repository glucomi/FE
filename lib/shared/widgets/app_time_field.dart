import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/widgets/ruler_picker.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

/// 오후 02:03
String formatFieldTime(TimeOfDay t) {
  final period = t.hour < 12 ? '오전' : '오후';
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  String two(int v) => v.toString().padLeft(2, '0');
  return '$period ${two(hour)}:${two(t.minute)}';
}

/// Figma COM-03 (시간): 라벨 + 48px 선택 박스
class AppTimeField extends StatelessWidget {
  const AppTimeField({
    super.key,
    required this.time,
    this.onTap,
    this.label = '시간',
  });

  final TimeOfDay time;

  /// 없으면 탭할 수 없음
  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = formatFieldTime(time);
    return Semantics(
      button: onTap != null,
      label: '$label $text',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.labelMeta.copyWith(
                color: AppColors.foregroundPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing2),
            Container(
              height: AppSpacing.controlHeightLg,
              padding: const EdgeInsets.all(AppSpacing.spacing2),
              decoration: BoxDecoration(
                color: AppColors.neutralsBackground,
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/common/time.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: AppSpacing.spacing1),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.bodySmM.copyWith(
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시간 선택 (COM-POP-03). 선택 완료를 누르면 고른 시간, 그냥 닫으면 null
Future<TimeOfDay?> showAppTimeSheet(
  BuildContext context, {
  required TimeOfDay selected,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: (context) => AppTimeSheet(selected: selected),
  );
}

/// 오전/오후 · 시 · 분 휠
class AppTimeSheet extends StatefulWidget {
  const AppTimeSheet({super.key, required this.selected});

  final TimeOfDay selected;

  @override
  State<AppTimeSheet> createState() => _AppTimeSheetState();
}

class _AppTimeSheetState extends State<AppTimeSheet> {
  static const _periods = ['오전', '오후'];
  static final _hours = [for (var h = 1; h <= 12; h++) '$h'];
  static final _minutes = [for (var m = 0; m < 60; m++) '$m'];

  late int _period = widget.selected.hour >= 12 ? 1 : 0;

  /// 0 = 1시 … 11 = 12시
  late int _hour =
      (widget.selected.hourOfPeriod == 0 ? 12 : widget.selected.hourOfPeriod) -
      1;
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
                      key: const ValueKey('app-time-period'),
                      labels: _periods,
                      initial: _period,
                      onChanged: (i) => setState(() => _period = i),
                    ),
                    const SizedBox(width: AppSpacing.spacing4),
                    _Wheel(
                      key: const ValueKey('app-time-hour'),
                      labels: _hours,
                      initial: _hour,
                      onChanged: (i) => setState(() => _hour = i),
                    ),
                    const SizedBox(width: AppSpacing.spacing4),
                    _Wheel(
                      key: const ValueKey('app-time-minute'),
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
            key: const ValueKey('app-time-done'),
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
