import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/widgets/calendar_day.dart';

/// 달력 전체보기 (COM-POP-10). 날짜를 누르면 그 날짜를 돌려줌
Future<DateTime?> showMonthCalendarSheet(
  BuildContext context, {
  required DateTime today,
  DateTime? selected,
  Map<DateTime, int> scores = const {},
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: (context) => MonthCalendarSheet(
      today: today,
      selected: selected,
      scores: scores,
    ),
  );
}

class MonthCalendarSheet extends StatefulWidget {
  const MonthCalendarSheet({
    super.key,
    required this.today,
    this.selected,
    this.scores = const {},
  });

  final DateTime today;

  /// 홈에서 보고 있는 날짜 (검정 글씨로 표시)
  final DateTime? selected;

  /// 날짜별 혈당 점수 (자정 기준 날짜 키)
  final Map<DateTime, int> scores;

  @override
  State<MonthCalendarSheet> createState() => _MonthCalendarSheetState();
}

class _MonthCalendarSheetState extends State<MonthCalendarSheet> {
  static const _weekdays = ['일', '월', '화', '수', '목', '금', '토'];

  late DateTime _today;
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final t = widget.today;
    _today = DateTime(t.year, t.month, t.day);
    final base = widget.selected ?? _today;
    _month = DateTime(base.year, base.month);
  }

  bool get _canGoNext =>
      DateTime(_month.year, _month.month + 1).isBefore(
        DateTime(_today.year, _today.month + 1),
      );

  void _moveMonth(int delta) {
    if (delta > 0 && !_canGoNext) return;
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  /// 일요일 시작, 이번 달을 모두 포함하는 주 단위 날짜 목록
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
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final selected = widget.selected == null
        ? null
        : DateTime(
            widget.selected!.year,
            widget.selected!.month,
            widget.selected!.day,
          );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border(top: BorderSide(color: AppColors.borderStrong)),
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.radius3xl),
        ),
        boxShadow: AppShadows.lg,
      ),
      child: Stack(
        children: [
          // 드래그 핸들
          Positioned(
            top: 15,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFBCBCBF),
                  borderRadius: BorderRadius.circular(AppRadius.radius3xl),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.spacing4,
              40,
              AppSpacing.spacing4,
              bottomInset > 0 ? bottomInset : AppSpacing.spacing6,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MonthHeader(
                  month: _month,
                  canGoNext: _canGoNext,
                  onPrev: () => _moveMonth(-1),
                  onNext: () => _moveMonth(1),
                ),
                const SizedBox(height: AppSpacing.spacing4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 48,
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
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.spacing2,
                          ),
                          child: Row(
                            children: [
                              for (final date in week)
                                Expanded(child: _buildDay(date, selected)),
                            ],
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

  Widget _buildDay(DateTime date, DateTime? selected) {
    final isToday = date == _today;
    final isFuture = date.isAfter(_today);
    final isSelected = date == selected;

    return CalendarDayCell(
      key: ValueKey('month-calendar-${date.month}-${date.day}'),
      label: isToday ? 'TODAY' : '${date.day}',
      labelStyle: isToday
          ? AppTypography.labelNav.copyWith(color: AppColors.foregroundTertiary)
          : AppTypography.bodySmR.copyWith(
              color: isSelected
                  ? AppColors.foregroundPrimary
                  : AppColors.neutralsEmphasis,
            ),
      score: widget.scores[date],
      dimmed: date.month != _month.month,
      onTap: isFuture ? null : () => Navigator.of(context).pop(date),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.canGoNext,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final label = '${month.year}.${month.month.toString().padLeft(2, '0')}';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ChevronButton(
          asset: 'assets/home/chevron_left_24.svg',
          semanticLabel: '이전 달',
          onTap: onPrev,
        ),
        const SizedBox(width: AppSpacing.spacing4),
        Text(
          label,
          style: AppTypography.headingH3.copyWith(
            color: AppColors.foregroundPrimary,
          ),
        ),
        const SizedBox(width: AppSpacing.spacing4),
        Opacity(
          opacity: canGoNext ? 1 : 0.3,
          child: _ChevronButton(
            asset: 'assets/home/chevron_right_24.svg',
            semanticLabel: '다음 달',
            onTap: canGoNext ? onNext : null,
          ),
        ),
      ],
    );
  }
}

class _ChevronButton extends StatelessWidget {
  const _ChevronButton({
    required this.asset,
    required this.semanticLabel,
    this.onTap,
  });

  final String asset;
  final String semanticLabel;
  final VoidCallback? onTap;

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
