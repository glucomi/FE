import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

/// 날짜 선택 (COM-POP-04). 선택 완료를 누르면 고른 날짜, 그냥 닫으면 null
Future<DateTime?> showWeightDateSheet(
  BuildContext context, {
  required DateTime selected,
  required DateTime today,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: (context) => WeightDateSheet(selected: selected, today: today),
  );
}

class WeightDateSheet extends StatefulWidget {
  const WeightDateSheet({
    super.key,
    required this.selected,
    required this.today,
  });

  final DateTime selected;
  final DateTime today;

  @override
  State<WeightDateSheet> createState() => _WeightDateSheetState();
}

class _WeightDateSheetState extends State<WeightDateSheet> {
  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  late DateTime _today;
  late DateTime _selected;
  late DateTime _month;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _today = _dateOnly(widget.today);
    _selected = _dateOnly(widget.selected);
    _month = DateTime(_selected.year, _selected.month);
  }

  void _moveMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  /// 일요일 시작, 앞뒤 달 날짜까지 채운 주 단위 목록
  List<List<DateTime>> get _weeks {
    final first = DateTime(_month.year, _month.month);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday % 7; // 일요일 = 0
    final weekCount = ((leading + daysInMonth) / 7).ceil();
    return [
      for (var w = 0; w < weekCount; w++)
        [
          for (var d = 0; d < 7; d++)
            DateTime(first.year, first.month, 1 - leading + w * 7 + d),
        ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final label = '${_month.year}.${_month.month.toString().padLeft(2, '0')}';

    return AppBottomSheetFrame(
      // COM-07 (높이 56) 안 버튼 48 아래 여백
      bottomPadding: AppSpacing.spacing2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ChevronButton(
                asset: 'assets/home/chevron_left_24.svg',
                semanticLabel: '이전 달',
                onTap: () => _moveMonth(-1),
              ),
              const SizedBox(width: AppSpacing.spacing4),
              Text(
                label,
                style: AppTypography.headingH3.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing4),
              _ChevronButton(
                asset: 'assets/home/chevron_right_24.svg',
                semanticLabel: '다음 달',
                onTap: () => _moveMonth(1),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing3),
            child: Column(
              children: [
                SizedBox(
                  height: AppSpacing.controlHeightLg,
                  child: Row(
                    children: [
                      for (final w in _weekdays)
                        Expanded(
                          child: Center(
                            child: Text(
                              w,
                              style: AppTypography.labelMeta.copyWith(
                                color: AppColors.foregroundTertiary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                for (final week in _weeks)
                  SizedBox(
                    height: AppSpacing.controlHeightLg,
                    child: Row(
                      children: [
                        for (final date in week) Expanded(child: _buildDay(date)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          AppButton(
            key: const ValueKey('weight-date-done'),
            label: '선택 완료',
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }

  Widget _buildDay(DateTime date) {
    final inMonth = date.month == _month.month;
    final isSelected = inMonth && date == _selected;
    final isToday = inMonth && date == _today;

    final TextStyle style;
    BoxDecoration? decoration;
    if (!inMonth) {
      style = AppTypography.bodyLgR.copyWith(color: AppColors.neutralsEmphasis);
    } else if (isSelected) {
      style = AppTypography.bodyLgM.copyWith(color: AppColors.gray10);
      decoration = const BoxDecoration(
        color: AppColors.gray800,
        shape: BoxShape.circle,
      );
    } else if (isToday) {
      style = AppTypography.bodyLgM.copyWith(color: AppColors.gray800);
      decoration = BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.gray800),
      );
    } else {
      style = AppTypography.bodyLgR.copyWith(color: AppColors.foregroundPrimary);
    }

    return Semantics(
      button: inMonth,
      selected: isSelected,
      label: '${date.month}월 ${date.day}일',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('weight-date-${date.month}-${date.day}'),
        onTap: inMonth ? () => setState(() => _selected = date) : null,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Container(
            width: AppSpacing.controlHeightMd,
            height: AppSpacing.controlHeightMd,
            alignment: Alignment.center,
            decoration: decoration,
            child: Text('${date.day}', style: style),
          ),
        ),
      ),
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({
    required this.asset,
    required this.semanticLabel,
    required this.onTap,
  });

  final String asset;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SvgPicture.asset(asset, width: 24, height: 24),
      ),
    );
  }
}
