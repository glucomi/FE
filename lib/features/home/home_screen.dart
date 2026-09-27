import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/home/widgets/add_record_menu.dart';
import 'package:glucomi/features/home/widgets/cgm_chart.dart';
import 'package:glucomi/features/home/widgets/daily_record_list.dart';
import 'package:glucomi/features/home/widgets/glucose_stats.dart';
import 'package:glucomi/features/home/widgets/glucose_summary.dart';
import 'package:glucomi/features/home/widgets/home_dock_bar.dart';
import 'package:glucomi/features/home/widgets/home_hero.dart';
import 'package:glucomi/features/home/widgets/month_calendar_sheet.dart';
import 'package:glucomi/features/home/widgets/week_calendar_card.dart';

/// MO-HOME-010 홈
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.data,
    this.onRefresh,
    this.onAddRecord,
    this.onSelectDate,
  });

  final HomeData data;

  /// 새로고침 버튼 (센서 데이터 다시 불러오기)
  final Future<void> Function()? onRefresh;

  /// + 메뉴에서 기록 종류를 골랐을 때
  final ValueChanged<AddRecordType>? onAddRecord;

  /// 달력 전체보기에서 날짜를 골랐을 때
  final ValueChanged<DateTime>? onSelectDate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Figma 기준 상단 영역 높이 (상태바 제외)
  static const double _heroHeight = 264;
  static const double _calendarTop = 171;
  static const double _contentTop = 278;

  // 그래프를 만지는 동안 페이지 스크롤 잠금
  bool _chartActive = false;

  final GlobalKey _fabKey = GlobalKey();

  /// 달력 전체보기에서 마지막으로 고른 날짜
  DateTime? _selectedDate;

  Future<void> _openCalendar() async {
    final data = widget.data;
    final picked = await showMonthCalendarSheet(
      context,
      today: data.date,
      selected: _selectedDate ?? data.date,
      scores: data.calendarScores,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);

    if (widget.onSelectDate != null) {
      widget.onSelectDate!(picked);
    } else if (!DateUtils.isSameDay(picked, data.date)) {
      _notReady('${picked.month}월 ${picked.day}일 기록 보기');
    }
  }

  Future<void> _openAddMenu() async {
    final fabBox = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (fabBox == null || overlayBox == null) return;
    final topLeft = fabBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    final type = await showAddRecordMenu(
      context,
      fabRect: topLeft & fabBox.size,
    );
    if (type == null || !mounted) return;

    if (widget.onAddRecord != null) {
      widget.onAddRecord!(type);
    } else {
      _notReady('${type.label} 기록');
    }
  }

  void _notReady(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature 준비 중입니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      bottomNavigationBar: HomeDockBar(
        current: HomeTab.home,
        onSelect: (tab) {
          if (tab != HomeTab.home) _notReady(tab.label);
        },
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: _chartActive
                ? const NeverScrollableScrollPhysics()
                : null,
            padding: const EdgeInsets.only(bottom: 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: topInset + _contentTop,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        top: topInset - 40,
                        height: 305,
                        child: Image.asset(
                          'assets/home/hero_bg.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: topInset,
                        height: _heroHeight,
                        child: HomeHero(
                          message: '지금 가볍게\n산책 어때요?',
                          showSuggestionChips: data.hasGlucose,
                          onTapNotification: () => _notReady('알림'),
                        ),
                      ),
                      Positioned(
                        left: 17,
                        right: 17,
                        top: topInset + _calendarTop,
                        child: WeekCalendarCard(
                          today: data.date,
                          scores: data.calendarScores,
                          onTapAll: _openCalendar,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.spacing4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GlucoseSummary(
                        data: data,
                        onRefresh: () async {
                          if (widget.onRefresh != null) {
                            await widget.onRefresh!();
                          } else {
                            _notReady('새로고침');
                          }
                        },
                        onConnect: () => _notReady('센서 연결'),
                      ),
                      const SizedBox(height: AppSpacing.spacing6),
                      CgmChart(
                        key: const ValueKey('home-cgm-chart'),
                        points: data.points,
                        records: data.records,
                        targetMin: data.rangeMin,
                        targetMax: data.rangeMax,
                        now: data.date,
                        onInteractionChanged: (active) {
                          if (_chartActive != active) {
                            setState(() => _chartActive = active);
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.spacing6),
                      GlucoseStats(data: data),
                      const SizedBox(height: AppSpacing.spacing6),
                      DailyRecordList(
                        records: data.records,
                        onTapDailyCard: () => _notReady('일일 카드'),
                        onTapRecord: (_) => _notReady('기록 상세'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 22,
            bottom: 9,
            child: _AddRecordButton(key: _fabKey, onTap: _openAddMenu),
          ),
        ],
      ),
    );
  }
}

class _AddRecordButton extends StatelessWidget {
  const _AddRecordButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '기록 추가',
      child: GestureDetector(
        key: const ValueKey('home-add-record'),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accentsBrand,
            shape: BoxShape.circle,
            boxShadow: AppShadows.md,
          ),
          child: SvgPicture.asset('assets/home/plus.svg', width: 26, height: 26),
        ),
      ),
    );
  }
}
