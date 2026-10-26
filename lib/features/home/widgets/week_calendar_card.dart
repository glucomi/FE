import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/widgets/calendar_day.dart';

/// 홈 주간 달력 카드 (오늘 포함 최근 7일)
class WeekCalendarCard extends StatelessWidget {
  const WeekCalendarCard({
    super.key,
    required this.today,
    this.scores = const {},
    this.onTapAll,
  });

  final DateTime today;

  /// 날짜별 혈당 점수 (자정 기준 날짜 키, 없으면 '-')
  final Map<DateTime, int> scores;
  final VoidCallback? onTapAll;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  Widget build(BuildContext context) {
    final day = DateTime(today.year, today.month, today.day);
    final days = [for (var i = 6; i >= 0; i--) day.subtract(Duration(days: i))];

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.gray0,
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 23,
            child: Row(
              children: [
                Text(
                  '${day.year}년 ${day.month}월 ${day.day}일(${_weekdays[day.weekday - 1]})',
                  style: AppTypography.bodyMdM.copyWith(
                    color: const Color(0xFF2F2F2F),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: onTapAll,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    '전체보기',
                    style: AppTypography.btnSm.copyWith(
                      color: AppColors.foregroundQuaternary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final date in days)
                Expanded(
                  child: CalendarDayCell(
                    label: date == day ? 'TODAY' : '${date.day}',
                    labelStyle: AppTypography.bodySmR.copyWith(
                      color: AppColors.neutralsEmphasis,
                    ),
                    score: scores[date],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
