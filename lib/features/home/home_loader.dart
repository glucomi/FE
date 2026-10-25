import 'package:flutter/material.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/core/api/cgm_api.dart';
import 'package:glucomi/core/api/home_api.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/home/home_screen.dart';
import 'package:glucomi/features/meal/api_meal_food_repository.dart';
import 'package:glucomi/features/weight/weight_models.dart';
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

  /// 체중 API 가 아직 없어서 화면 안에서만 유지
  final _weightRepository = SampleWeightRepository();

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
      if (!mounted || requestId != _requestId) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      _message(e, '홈 정보를 불러오지 못했어요.');
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
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
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              opened
                  ? '아이센스 로그인을 마친 뒤 새로고침을 눌러주세요.'
                  : '아이센스 로그인 페이지를 열지 못했어요.',
            ),
          ),
        );
    } catch (e) {
      _message(e, '센서 연결을 시작하지 못했어요.');
    }
    return null;
  }

  void _message(Object error, String fallback) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : fallback;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
