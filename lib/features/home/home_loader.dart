import 'package:flutter/material.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/core/api/cgm_api.dart';
import 'package:glucomi/core/api/home_api.dart';
import 'package:glucomi/features/drug/api_drug_repository.dart';
import 'package:glucomi/features/exercise/api_exercise_repository.dart';
import 'package:glucomi/features/glucose_record/api_glucose_record_repository.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/home/home_screen.dart';
import 'package:glucomi/features/insulin/api_insulin_repository.dart';
import 'package:glucomi/features/meal/api_meal_food_repository.dart';
import 'package:glucomi/features/memo/api_memo_repository.dart';
import 'package:glucomi/features/weight/api_weight_repository.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

/// 서버 데이터로 홈을 띄우는 화면 (로그인 상태에서 사용)
///
/// GET /api/home, /api/glucose/daily-scores 로 날짜별 데이터를 불러오고
/// 새로고침은 /api/cgm/sync 후 다시 불러옴
class HomeLoader extends StatefulWidget {
  const HomeLoader({
    super.key,
    this.initialDate,
    this.targetMin,
    this.targetMax,
    this.homeApi,
    this.cgmApi,
  });

  final DateTime? initialDate;

  /// 불러오기 전 잠깐 보여줄 목표 범위 (큐레이션 직후 값)
  final int? targetMin;
  final int? targetMax;

  final HomeApi? homeApi;
  final CgmApi? cgmApi;

  @override
  State<HomeLoader> createState() => _HomeLoaderState();
}

class _HomeLoaderState extends State<HomeLoader> {
  late final HomeApi _homeApi = widget.homeApi ?? HomeApi();
  late final CgmApi _cgmApi = widget.cgmApi ?? CgmApi();
  final _mealRepository = ApiMealFoodRepository();
  final _weightRepository = ApiWeightRepository();
  final _drugRepository = ApiDrugRepository();
  final _exerciseRepository = ApiExerciseRepository();
  final _insulinRepository = ApiInsulinRepository();
  final _glucoseRepository = ApiGlucoseRecordRepository();
  final _memoRepository = ApiMemoRepository();

  late DateTime _date = _dayOf(widget.initialDate ?? DateTime.now());
  late HomeData _data = HomeData.empty(
    date: _date,
    targetMin: widget.targetMin,
    targetMax: widget.targetMax,
  );
  bool _loading = false;

  /// 늦게 도착한 이전 날짜 응답은 버림
  int _requestId = 0;

  static DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  @override
  void initState() {
    super.initState();
    _load(_date);
  }

  Future<void> _load(DateTime date) async {
    final day = _dayOf(date);
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      if (day != _date) {
        _date = day;
        _data = HomeData.empty(
          date: day,
          targetMin: _data.targetMin,
          targetMax: _data.targetMax,
        );
      }
    });

    try {
      final scores = _homeApi
          .dailyScores(
            day.subtract(const Duration(days: HomeApi.maxScoreDays - 1)),
            day,
          )
          // 점수를 못 불러와도 홈은 보여줌
          .catchError((_) => <DateTime, int>{});
      final data = await _homeApi.fetch(day, dailyScores: await scores);
      final extra = await _recordsOf(day, requestId);
      if (!mounted || requestId != _requestId) return;
      setState(() => _data = data.withAddedRecords(extra));
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      _message(e, '홈 정보를 불러오지 못했어요.');
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  /// 홈 API(CGM·식단) 외의 기록을 날짜별로 불러옴
  ///
  /// 기록 종류마다 따로 불러와서 하나가 실패해도 나머지는 보여주고,
  /// 실패한 종류는 토스트로 알려 줌
  Future<List<DailyRecord>> _recordsOf(DateTime day, int requestId) async {
    final failed = <String>[];
    Future<List<DailyRecord>> load(
      String label,
      Future<List<DailyRecord>> Function() fetch,
    ) async {
      try {
        return await fetch();
      } catch (_) {
        failed.add(label);
        return const [];
      }
    }

    final groups = await Future.wait([
      load(
        '혈당',
        () async => [
          for (final r in await _glucoseRepository.byDate(day))
            DailyRecord(
              time: r.time,
              type: DailyRecordType.glucose,
              title: '${r.mgDl} mg/dL',
              glucose: r,
            ),
        ],
      ),
      load(
        '복약',
        () async => [
          for (final r in await _drugRepository.byDate(day))
            DailyRecord(
              time: r.time,
              type: DailyRecordType.medicine,
              title: r.type.label,
              details: [?r.productName],
              drug: r,
            ),
        ],
      ),
      load('체중', () async {
        final r = await _weightRepository.byDate(day);
        return [if (r != null) DailyRecord.fromWeight(r)];
      }),
      load(
        '운동',
        () async => [
          for (final r in await _exerciseRepository.byDate(day))
            DailyRecord.fromExercise(r),
        ],
      ),
      load(
        '인슐린',
        () async => [
          for (final r in await _insulinRepository.byDate(day))
            DailyRecord.insulin(r),
        ],
      ),
      load(
        '메모',
        () async => [
          for (final r in await _memoRepository.byDate(day))
            DailyRecord.fromMemo(r),
        ],
      ),
    ]);
    if (failed.isNotEmpty && mounted && requestId == _requestId) {
      showAppToast(
        context,
        '${failed.join('·')} 기록을 불러오지 못했어요.',
        type: AppToastType.error,
      );
    }
    return [for (final g in groups) ...g];
  }

  /// 새로고침 — 센서가 연결돼 있으면 보고 있는 날짜의 CGM 데이터를 먼저 가져옴
  Future<void> _refresh() async {
    if (_data.sensorConnected) {
      final now = DateTime.now();
      final nextDay = _date.add(const Duration(days: 1));
      try {
        await _cgmApi.sync(
          start: _date,
          end: now.isBefore(nextDay) ? now : nextDay,
        );
      } catch (e) {
        _message(e, '센서 데이터를 가져오지 못했어요.');
      }
    }
    await _load(_date);
  }

  /// 연결하기 — 아이센스 로그인 페이지를 열고, 로그인 후 새로고침으로 반영
  Future<HomeData?> _connectSensor() async {
    try {
      final url = await _cgmApi.authorizeUrl();
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!mounted) return null;
      showAppToast(
        context,
        opened ? '아이센스 로그인을 마친 뒤 새로고침을 눌러주세요.' : '아이센스 로그인 페이지를 열지 못했어요.',
        type: opened ? AppToastType.info : AppToastType.error,
      );
    } catch (e) {
      _message(e, '센서 연결을 시작하지 못했어요.');
    }
    return null;
  }

  void _message(Object error, String fallback) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : fallback;
    showAppToast(context, message, type: AppToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        HomeScreen(
          // 날짜를 바꾸면 화면 안에서만 덧붙인 기록은 초기화
          key: ValueKey(_date),
          data: _data,
          onRefresh: _refresh,
          onSelectDate: _load,
          onConnectSensor: _connectSensor,
          onRecordsChanged: () => _load(_date),
          mealRepository: _mealRepository,
          weightRepository: _weightRepository,
          drugRepository: _drugRepository,
          exerciseRepository: _exerciseRepository,
          insulinRepository: _insulinRepository,
          glucoseRepository: _glucoseRepository,
          memoRepository: _memoRepository,
        ),
        if (_loading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
