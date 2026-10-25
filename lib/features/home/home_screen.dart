import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/camera/food_camera_screen.dart';
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
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/meal_record_screen.dart';
import 'package:glucomi/features/weight/weight_models.dart';
import 'package:glucomi/features/weight/weight_record_screen.dart';

/// MO-HOME-010 홈
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.data,
    this.onRefresh,
    this.onAddRecord,
    this.onSelectDate,
    this.mealRepository,
    this.weightRepository,
    this.onConnectSensor,
    this.onRecordsChanged,
  });

  final HomeData data;

  /// 새로고침 버튼 (센서 데이터 다시 불러오기)
  final Future<void> Function()? onRefresh;

  /// + 메뉴에서 기록 종류를 골랐을 때
  final ValueChanged<AddRecordType>? onAddRecord;

  /// 달력 전체보기에서 날짜를 골랐을 때
  final ValueChanged<DateTime>? onSelectDate;

  /// 음식 검색 데이터 (있으면 + 메뉴의 식단에서 음식 기록하기 화면을 엶)
  final MealFoodRepository? mealRepository;

  /// 체중 저장소 (있으면 + 메뉴의 체중과 오늘의 기록 체중 카드에서 체중 화면을 엶)
  final WeightRepository? weightRepository;

  /// 연결하기를 눌렀을 때 센서를 연결하고 새 데이터를 돌려줌
  /// (없으면 예시 데이터로 연결된 화면을 보여줌)
  final Future<HomeData?> Function()? onConnectSensor;

  /// 서버에 기록을 저장한 뒤 홈 데이터를 다시 불러옴
  /// (없으면 새 기록을 화면에만 덧붙임)
  final Future<void> Function()? onRecordsChanged;

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

  /// 이 화면에서 새로 기록한 항목 (서버 연동 전까지 화면에만 반영)
  final List<DailyRecord> _addedRecords = [];

  /// 이 화면에서 지우거나 새 값으로 바꾼 기존 항목
  final Set<DailyRecord> _removedRecords = {};

  /// 연결하기로 센서를 연결한 뒤의 데이터 (서버 연동 전까지 예시 데이터)
  HomeData? _connectedData;

  HomeData get _data =>
      (_connectedData ?? widget.data).withAddedRecords(
        _addedRecords,
        removed: _removedRecords,
      );

  Future<void> _connectSensor() async {
    if (widget.onConnectSensor != null) {
      final data = await widget.onConnectSensor!();
      if (data == null || !mounted) return;
      setState(() => _connectedData = data);
      return;
    }
    // 센서 연동 전: 목표 범위는 그대로 두고 예시 측정값으로 연결된 화면을 보여줌
    final current = widget.data;
    setState(() {
      _connectedData = HomeData.sample(
        today: current.date,
        targetMin: current.targetMin ?? 70,
        targetMax: current.targetMax ?? 140,
      );
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('센서가 연결됐어요. (예시 데이터)')),
      );
  }

  Future<void> _openCalendar() async {
    final data = _data;
    final picked = await showMonthCalendarSheet(
      context,
      today: data.date,
      // 홈에서 보고 있는 날짜 (달력은 이 날짜가 있는 달부터 보여줌)
      selected: data.date,
      scores: data.calendarScores,
    );
    if (picked == null || !mounted) return;

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
    } else if (type == AddRecordType.food && widget.mealRepository != null) {
      await _openMealRecord(widget.mealRepository!);
    } else if (type == AddRecordType.weight && widget.weightRepository != null) {
      await _openWeightRecord(widget.weightRepository!);
    } else {
      _notReady('${type.label} 기록');
    }
  }

  Future<void> _openMealRecord(MealFoodRepository repository) async {
    final record = await Navigator.of(context).push<MealRecord>(
      MaterialPageRoute(
        builder: (_) => MealRecordScreen(repository: repository),
      ),
    );
    if (record == null || record.entries.isEmpty || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (widget.onRecordsChanged != null) {
      // 음식 기록하기 화면에서 이미 서버에 저장됨 → 홈을 새로 불러옴
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('식단을 기록했어요.')));
      await widget.onRecordsChanged!();
      return;
    }

    final carbs = record.carbs.round();
    setState(() {
      _addedRecords.add(
        DailyRecord(
          time: record.time,
          type: DailyRecordType.food,
          title: record.title,
          details: ['총 ${record.kcal.round()} kcal', '총 탄수화물 $carbs g'],
          carbsGram: carbs.toDouble(),
        ),
      );
    });
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('식단을 기록했어요.')));
  }

  /// 오늘의 기록 중 가장 마지막 체중
  DailyRecord? get _latestWeight {
    DailyRecord? latest;
    for (final r in _data.records) {
      if (r.weightKg == null) continue;
      if (latest == null || !r.time.isBefore(latest.time)) latest = r;
    }
    return latest;
  }

  /// MO-WEIGHT-010. [existing] 이 있으면 (b) 등록후 상태로 엶
  Future<void> _openWeightRecord(
    WeightRepository repository, {
    DailyRecord? existing,
  }) async {
    final result = await Navigator.of(context).push<WeightRecordResult>(
      MaterialPageRoute(
        builder: (_) => WeightRecordScreen(
          repository: repository,
          today: _data.date,
          record: existing == null
              ? null
              : WeightRecord(date: existing.time, kg: existing.weightKg!),
          previousKg: existing == null ? _latestWeight?.weightKg : null,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final data = _data;
    setState(() {
      if (existing != null) _forget(existing);
      final saved = result.record;
      // 홈에서 보고 있는 날짜의 기록만 오늘의 기록·그래프에 반영
      if (saved == null || !DateUtils.isSameDay(saved.date, data.date)) return;
      // 같은 날짜 기록은 최신값으로 갱신 → 그날 기존 체중 항목은 정리
      for (final r in data.records) {
        if (r.weightKg != null && DateUtils.isSameDay(r.time, saved.date)) {
          _forget(r);
        }
      }
      final now = DateTime.now();
      final time =
          existing != null && DateUtils.isSameDay(existing.time, saved.date)
          ? existing.time
          : DateTime(
              saved.date.year,
              saved.date.month,
              saved.date.day,
              now.hour,
              now.minute,
            );
      _addedRecords.add(
        DailyRecord(
          time: time,
          type: DailyRecordType.weight,
          title: '${saved.kg.toStringAsFixed(1)} kg',
          weightKg: saved.kg,
        ),
      );
    });
  }

  void _forget(DailyRecord record) {
    if (!_addedRecords.remove(record)) _removedRecords.add(record);
  }

  void _onTapRecord(DailyRecord record) {
    final repository = widget.weightRepository;
    if (record.weightKg != null && repository != null) {
      _openWeightRecord(repository, existing: record);
    } else {
      _notReady('기록 상세');
    }
  }

  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const FoodCameraScreen(),
      ),
    );
  }

  void _notReady(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature 준비 중입니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      bottomNavigationBar: HomeDockBar(
        current: HomeTab.home,
        onSelect: (tab) {
          switch (tab) {
            case HomeTab.home:
              break;
            case HomeTab.camera:
              _openCamera();
            case HomeTab.farm || HomeTab.myPage:
              _notReady(tab.label);
          }
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
                        onConnect: _connectSensor,
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
                        onTapRecord: _onTapRecord,
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
