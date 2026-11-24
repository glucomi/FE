import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/attach/cgm_attach_flow.dart';
import 'package:glucomi/features/attach/cgm_attach_models.dart';
import 'package:glucomi/features/camera/food_analysis.dart';
import 'package:glucomi/features/camera/food_camera_screen.dart';
import 'package:glucomi/features/chat/chat_screen.dart';
import 'package:glucomi/features/drug/drug_models.dart';
import 'package:glucomi/features/drug/drug_record_screen.dart';
import 'package:glucomi/features/exercise/exercise_models.dart';
import 'package:glucomi/features/exercise/exercise_record_screen.dart';
import 'package:glucomi/features/glucose_record/glucose_record_models.dart';
import 'package:glucomi/features/glucose_record/glucose_record_screen.dart';
import 'package:glucomi/features/glycemic/glycemic_screen.dart';
import 'package:glucomi/features/home/home_models.dart';
import 'package:glucomi/features/home/widgets/add_record_menu.dart';
import 'package:glucomi/features/home/widgets/cgm_chart.dart';
import 'package:glucomi/features/home/widgets/daily_card_dialog.dart';
import 'package:glucomi/features/home/widgets/daily_record_list.dart';
import 'package:glucomi/features/home/widgets/glucose_stats.dart';
import 'package:glucomi/features/home/widgets/glucose_summary.dart';
import 'package:glucomi/features/home/widgets/home_dock_bar.dart';
import 'package:glucomi/features/home/widgets/home_hero.dart';
import 'package:glucomi/features/home/widgets/month_calendar_sheet.dart';
import 'package:glucomi/features/home/widgets/week_calendar_card.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/features/insulin/insulin_record_screen.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/meal_record_screen.dart';
import 'package:glucomi/features/meal/meal_save_screen.dart';
import 'package:glucomi/features/memo/memo_models.dart';
import 'package:glucomi/features/memo/memo_record_screen.dart';
import 'package:glucomi/features/mypage/mypage_models.dart';
import 'package:glucomi/features/mypage/mypage_screen.dart';
import 'package:glucomi/features/signup/signup_flow.dart';
import 'package:glucomi/features/weight/weight_models.dart';
import 'package:glucomi/features/weight/weight_record_screen.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';

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
    this.drugRepository,
    this.exerciseRepository,
    this.insulinRepository,
    this.glucoseRepository,
    this.memoRepository,
    this.onConnectSensor,
    this.onRecordsChanged,
    this.foodAnalysisRepository,
    this.loadDailyCard,
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

  /// 복약 저장소 (있으면 + 메뉴의 복약과 오늘의 기록 복약 카드에서 복약 화면을 엶)
  final DrugRepository? drugRepository;

  /// 운동 저장소 (있으면 + 메뉴의 운동과 이 화면에서 기록한 운동 카드에서 운동 화면을 엶)
  final ExerciseRepository? exerciseRepository;

  /// 인슐린 저장소 (있으면 + 메뉴의 인슐린과 오늘의 기록 인슐린 카드에서 인슐린 화면을 엶)
  final InsulinRepository? insulinRepository;

  /// 혈당 직접 기록 저장소 (있으면 + 메뉴의 혈당과 오늘의 기록 혈당 카드에서 혈당 화면을 엶)
  final GlucoseRecordRepository? glucoseRepository;

  /// 메모 저장소 (있으면 + 메뉴의 메모와 오늘의 기록 메모 카드에서 메모 화면을 엶)
  final MemoRepository? memoRepository;

  /// 연결하기를 눌렀을 때 센서를 연결하고 새 데이터를 돌려줌
  /// (없으면 예시 데이터로 연결된 화면을 보여줌)
  final Future<HomeData?> Function()? onConnectSensor;

  /// 서버에 기록을 저장한 뒤 홈 데이터를 다시 불러옴
  /// (없으면 새 기록을 화면에만 덧붙임)
  final Future<void> Function()? onRecordsChanged;

  /// AI 음식 촬영 분석 (없으면 예시 결과)
  final FoodAnalysisRepository? foodAnalysisRepository;

  /// COM-POP-11 일일카드 데이터 (없으면 빈 카드)
  final Future<DailyCardData> Function()? loadDailyCard;

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

  /// 이 화면에서 기록한 운동 카드 → 원본 기록 (카드 탭 시 (c) 등록후로 엶)
  final Map<DailyRecord, ExerciseRecord> _exerciseRecords = {};

  /// 연결하기로 센서를 연결한 뒤의 데이터 (서버 연동 전까지 예시 데이터)
  HomeData? _connectedData;

  /// 마이페이지 내 정보 (탭을 오가도 수정한 값 유지)
  final MyPageRepository _myPageRepository = MyPageRepository();

  HomeData get _data => (_connectedData ?? widget.data).withAddedRecords(
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
    showAppToast(context, '센서가 연결됐어요. (예시 데이터)', type: AppToastType.success);
  }

  /// MO-ATTACH-010 cgm 연결 — 홈 '연결하기'·마이페이지 '센서 연결'
  Future<void> _openAttach() async {
    final homeRoute = ModalRoute.of(context);
    final connected = await openCgmAttach(
      context,
      onConnect: (request) async {
        if (request.type == CgmSensorType.libre) {
          // 리브레 연동 API 없음 (docs/be-requests.md)
          showAttachNotReady(context, request.type);
          return false;
        }
        await _connectSensor();
        return true;
      },
    );
    // (e) 연결 성공 → 확인: 마이페이지에서 들어왔어도 홈으로
    if (connected && mounted && homeRoute != null) {
      Navigator.of(context).popUntil((route) => route == homeRoute);
    }
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
    } else if (type == AddRecordType.weight &&
        widget.weightRepository != null) {
      await _openWeightRecord(widget.weightRepository!);
    } else if (type == AddRecordType.medicine &&
        widget.drugRepository != null) {
      await _openDrugRecord(widget.drugRepository!);
    } else if (type == AddRecordType.exercise &&
        widget.exerciseRepository != null) {
      await _openExerciseRecord(widget.exerciseRepository!);
    } else if (type == AddRecordType.insulin &&
        widget.insulinRepository != null) {
      await _openInsulinRecord(widget.insulinRepository!);
    } else if (type == AddRecordType.glucose &&
        widget.glucoseRepository != null) {
      await _openGlucoseRecord(widget.glucoseRepository!);
    } else if (type == AddRecordType.memo && widget.memoRepository != null) {
      await _openMemoRecord(widget.memoRepository!);
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
    showAppToastOn(messenger, '식단을 기록했어요.', type: AppToastType.success);
    final card = await _addMealCard(record);
    // MO-MEAL-040 ⑦ 저장하기 → MO-GLYCEMIC-010
    if (mounted) await _openGlycemic(card);
  }

  /// 저장한 식사를 오늘의 기록에 반영 (서버 연동 시 홈을 새로 불러옴)
  Future<DailyRecord> _addMealCard(
    MealRecord record, {
    AiFoodStatus? aiStatus,
    Uint8List? photo,
  }) async {
    final carbs = record.carbs.round();
    final card = DailyRecord(
      time: record.time,
      type: DailyRecordType.food,
      title: record.title,
      details: ['총 ${record.kcal.round()} kcal', '총 탄수화물 $carbs g'],
      carbsGram: carbs.toDouble(),
      kcal: record.kcal,
      meal: record,
      photoBytes: photo,
      aiStatus: aiStatus,
    );
    if (widget.onRecordsChanged != null) {
      // 기록 화면에서 이미 서버에 저장됨 → 홈을 새로 불러옴
      await widget.onRecordsChanged!();
      return card;
    }
    if (mounted && DateUtils.isSameDay(record.time, _data.date)) {
      setState(() => _addedRecords.add(card));
    }
    return card;
  }

  /// MO-GLYCEMIC-010 혈당 반응
  ///
  /// 서버 기록(mealRecordId)은 GET /api/meal-records/{id} 로 음식별 정보를 불러옴
  Future<void> _openGlycemic(DailyRecord card) async {
    final online = widget.onRecordsChanged != null;
    final repository = widget.mealRepository;
    final serverId = card.mealRecordId;

    var record = card.meal;
    if (record == null && serverId != null && repository != null) {
      try {
        record = await repository.recordDetail(serverId);
      } catch (_) {
        // 상세를 못 불러와도 홈 요약(대표 음식·칼로리)으로 보여줌
      }
      if (!mounted) return;
    }
    final meal = record != null
        ? GlycemicMeal.fromRecord(record)
        : GlycemicMeal.fromSummary(
            time: card.time,
            title: card.title,
            kcal: card.kcal,
            carbs: card.carbsGram,
          );

    Future<bool> Function()? onDelete;
    if (!online) {
      onDelete = () async {
        setState(() => _forget(card));
        return true;
      };
    } else if (serverId != null && repository != null) {
      onDelete = () async {
        try {
          await repository.deleteRecord(serverId);
        } catch (_) {
          if (mounted) {
            showAppToast(context, '식사 기록을 삭제하지 못했어요.', type: AppToastType.error);
          }
          return false;
        }
        await widget.onRecordsChanged!();
        return true;
      };
    }

    // 서버 기록은 PUT, 화면 안에서만 기록한 식사는 카드 교체로 수정
    final canEdit =
        record != null &&
        repository != null &&
        (!online || serverId != null);
    final editable = record;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (glycemicContext) => GlycemicScreen(
          meal: meal,
          points: _data.points,
          aiRecorded: card.aiStatus == AiFoodStatus.done,
          onDelete: onDelete,
          onEdit: canEdit
              ? () => _editMeal(glycemicContext, card, editable!, repository!)
              : null,
        ),
      ),
    );
  }

  /// 수정하기 → MO-MEAL-040 (담긴 음식·일시 그대로) → 저장하면 혈당 반응 화면 새로 열기
  Future<void> _editMeal(
    BuildContext glycemicContext,
    DailyRecord card,
    MealRecord record,
    MealFoodRepository repository,
  ) async {
    final serverId = card.mealRecordId;
    final online = widget.onRecordsChanged != null;
    final updated = await Navigator.of(glycemicContext).push<MealRecord>(
      MaterialPageRoute(
        builder: (_) => MealSaveScreen(
          repository: online && serverId != null
              ? MealRecordUpdateRepository(repository, serverId)
              : repository,
          entries: record.entries,
          initialTime: record.time,
        ),
      ),
    );
    if (updated == null || !mounted) return;
    if (glycemicContext.mounted) Navigator.of(glycemicContext).pop();

    if (online) {
      await widget.onRecordsChanged!();
      if (!mounted) return;
      await _openGlycemic(
        DailyRecord(
          time: updated.time,
          type: DailyRecordType.food,
          title: updated.title,
          meal: updated,
          mealRecordId: serverId,
          kcal: updated.kcal,
          carbsGram: updated.carbs,
          aiStatus: card.aiStatus,
        ),
      );
      return;
    }
    setState(() => _forget(card));
    final next = await _addMealCard(
      updated,
      aiStatus: card.aiStatus,
      photo: card.photoBytes,
    );
    if (mounted) await _openGlycemic(next);
  }

  /// MO-CAMERA-010 분석 → 음식 DB 매칭 → 자동 확정 등록
  ///
  /// 카메라를 닫아도(분석 중 이탈) 이 작업은 계속 돌고, 오늘의 기록에 '분석중' 카드가 보임.
  /// 끝나면 식단을 저장하고 알림 대신 토스트로 알림 (웹은 앱 push 불가)
  Future<DailyRecord?> _runAiAnalysis(
    Uint8List bytes,
    String filename,
    DateTime time,
  ) async {
    final mealRepository = widget.mealRepository;
    if (mealRepository == null) {
      _notReady('AI 음식 분석');
      return null;
    }
    final messenger = ScaffoldMessenger.of(context);
    final pending = DailyRecord(
      time: time,
      type: DailyRecordType.food,
      title: '',
      photoBytes: bytes,
      aiStatus: AiFoodStatus.analyzing,
    );
    if (DateUtils.isSameDay(time, _data.date)) {
      setState(() => _addedRecords.add(pending));
    }
    void dropPending() {
      if (mounted) setState(() => _addedRecords.remove(pending));
    }

    try {
      final analysis =
          widget.foodAnalysisRepository ?? const SampleFoodAnalysisRepository();
      final result = await analysis.analyze(bytes, filename: filename);

      final entries = <MealEntry>[];
      final photos = <MealPhoto>[];
      for (final found in result.foods) {
        final food = await _matchFood(mealRepository, found);
        if (food == null) continue;
        entries.add(MealEntry.initial(food));
        if (photos.isEmpty) {
          photos.add(
            MealPhoto(
              bytes: bytes,
              foodId: food.id,
              label: food.name,
              center: found.center,
            ),
          );
        }
      }
      if (entries.isEmpty) {
        dropPending();
        showAppToastOn(
          messenger,
          '음식을 찾지 못했어요. 직접 검색해서 기록해 주세요.',
          type: AppToastType.error,
        );
        return null;
      }

      final record = MealRecord(time: time, entries: entries, photos: photos);
      await mealRepository.saveRecord(record);
      dropPending();
      showAppToastOn(
        messenger,
        'AI 분석이 끝나 식단을 기록했어요.',
        type: AppToastType.success,
      );
      if (!mounted) return null;
      return _addMealCard(
        record,
        aiStatus: AiFoodStatus.done,
        photo: bytes,
      );
    } catch (_) {
      dropPending();
      showAppToastOn(
        messenger,
        '사진을 분석하지 못했어요. 다시 시도해 주세요.',
        type: AppToastType.error,
      );
      return null;
    }
  }

  /// 분석 결과 음식명 → 음식 DB (서버가 foodId 를 주면 그 음식, 아니면 이름 검색 첫 결과)
  Future<MealFood?> _matchFood(
    MealFoodRepository repository,
    AnalyzedFood found,
  ) async {
    final results = await repository.search(found.name);
    if (results.isEmpty) return null;
    for (final food in results) {
      if (food.id == found.foodId || food.name == found.name) {
        return repository.detail(food);
      }
    }
    return repository.detail(results.first);
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
    if (widget.onRecordsChanged != null) {
      await widget.onRecordsChanged!();
      return;
    }

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

  /// MO-DRUG-010. [existing] 이 있으면 (e) 등록후 상태로 엶
  Future<void> _openDrugRecord(
    DrugRepository repository, {
    DailyRecord? existing,
  }) async {
    final result = await Navigator.of(context).push<DrugRecordResult>(
      MaterialPageRoute(
        builder: (_) =>
            DrugRecordScreen(repository: repository, record: existing?.drug),
      ),
    );
    if (result == null || !mounted) return;
    if (widget.onRecordsChanged != null) {
      await widget.onRecordsChanged!();
      return;
    }

    final data = _data;
    setState(() {
      if (existing != null) _forget(existing);
      final saved = result.record;
      // 홈에서 보고 있는 날짜의 기록만 오늘의 기록·그래프 마커에 반영
      if (saved == null || !DateUtils.isSameDay(saved.time, data.date)) return;
      _addedRecords.add(
        DailyRecord(
          time: saved.time,
          type: DailyRecordType.medicine,
          title: saved.type.label,
          details: [?saved.productName],
          drug: saved,
        ),
      );
    });
  }

  /// MO-INSULIN-010. [existing] 이 있으면 (f) 등록후 상태로 엶
  Future<void> _openInsulinRecord(
    InsulinRepository repository, {
    DailyRecord? existing,
  }) async {
    final result = await Navigator.of(context).push<InsulinRecordResult>(
      MaterialPageRoute(
        builder: (_) => InsulinRecordScreen(
          repository: repository,
          record: existing?.insulinRecord,
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (widget.onRecordsChanged != null) {
      await widget.onRecordsChanged!();
      return;
    }

    final data = _data;
    setState(() {
      if (existing != null) _forget(existing);
      final saved = result.record;
      // 홈에서 보고 있는 날짜의 기록만 오늘의 기록·그래프 마커에 반영
      if (saved == null || !DateUtils.isSameDay(saved.time, data.date)) return;
      _addedRecords.add(DailyRecord.insulin(saved));
    });
  }

  /// MO-GLUCOSER-010. [existing] 이 있으면 (c) 등록후 상태로 엶
  Future<void> _openGlucoseRecord(
    GlucoseRecordRepository repository, {
    DailyRecord? existing,
  }) async {
    final result = await Navigator.of(context).push<GlucoseRecordResult>(
      MaterialPageRoute(
        builder: (_) => GlucoseRecordScreen(
          repository: repository,
          today: _data.date,
          record: existing?.glucose,
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (widget.onRecordsChanged != null) {
      await widget.onRecordsChanged!();
      return;
    }

    final data = _data;
    setState(() {
      if (existing != null) _forget(existing);
      final saved = result.record;
      // 홈에서 보고 있는 날짜의 기록만 오늘의 기록·그래프에 반영
      if (saved == null || !DateUtils.isSameDay(saved.time, data.date)) return;
      _addedRecords.add(
        DailyRecord(
          time: saved.time,
          type: DailyRecordType.glucose,
          title: '${saved.mgDl} mg/dL',
          glucose: saved,
        ),
      );
    });
  }

  /// MO-MEMO-010. [existing] 이 있으면 (c) 등록후 상태로 엶
  Future<void> _openMemoRecord(
    MemoRepository repository, {
    DailyRecord? existing,
  }) async {
    final data = _data;
    final now = DateTime.now();
    final result = await Navigator.of(context).push<MemoRecordResult>(
      MaterialPageRoute(
        builder: (_) => MemoRecordScreen(
          repository: repository,
          record: existing?.memo,
          // 홈에서 보고 있는 날짜 + 현재 시각으로 진입
          now: DateTime(
            data.date.year,
            data.date.month,
            data.date.day,
            now.hour,
            now.minute,
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (widget.onRecordsChanged != null) {
      await widget.onRecordsChanged!();
      return;
    }

    setState(() {
      if (existing != null) _forget(existing);
      final saved = result.record;
      // 홈에서 보고 있는 날짜의 기록만 오늘의 기록·그래프 마커에 반영
      if (saved == null || !DateUtils.isSameDay(saved.time, data.date)) return;
      _addedRecords.add(DailyRecord.fromMemo(saved));
    });
  }

  void _forget(DailyRecord record) {
    if (!_addedRecords.remove(record)) _removedRecords.add(record);
  }

  /// MO-EXERCISE-010. [existing] 이 있으면 (c) 등록후 상태로 엶
  Future<void> _openExerciseRecord(
    ExerciseRepository repository, {
    DailyRecord? existing,
  }) async {
    final original = existing == null
        ? null
        : existing.exercise ?? _exerciseRecords[existing];
    final now = DateTime.now();
    final data = _data;
    final result = await Navigator.of(context).push<ExerciseRecordResult>(
      MaterialPageRoute(
        builder: (_) => ExerciseRecordScreen(
          repository: repository,
          record: original,
          // 홈에서 보고 있는 날짜 + 현재 시각으로 진입
          now: DateTime(
            data.date.year,
            data.date.month,
            data.date.day,
            now.hour,
            now.minute,
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;
    if (widget.onRecordsChanged != null) {
      await widget.onRecordsChanged!();
      return;
    }

    setState(() {
      if (existing != null) {
        _exerciseRecords.remove(existing);
        _forget(existing);
      }
      final saved = result.record;
      // 홈에서 보고 있는 날짜의 기록만 오늘의 기록·그래프 마커에 반영
      if (saved == null || !DateUtils.isSameDay(saved.time, data.date)) return;
      final card = DailyRecord(
        time: saved.time,
        type: DailyRecordType.exercise,
        title: saved.title,
        details: ['${saved.totalMinutes}분', '${saved.totalKcal} kcal'],
      );
      _exerciseRecords[card] = saved;
      _addedRecords.add(card);
    });
  }

  void _onTapRecord(DailyRecord record) {
    final repository = widget.weightRepository;
    final drugRepository = widget.drugRepository;
    final exerciseRepository = widget.exerciseRepository;
    final insulinRepository = widget.insulinRepository;
    final glucoseRepository = widget.glucoseRepository;
    if (record.weightKg != null && repository != null) {
      _openWeightRecord(repository, existing: record);
    } else if (record.drug != null && drugRepository != null) {
      _openDrugRecord(drugRepository, existing: record);
    } else if ((record.exercise != null ||
            _exerciseRecords.containsKey(record)) &&
        exerciseRepository != null) {
      _openExerciseRecord(exerciseRepository, existing: record);
    } else if (record.insulinRecord != null && insulinRepository != null) {
      _openInsulinRecord(insulinRepository, existing: record);
    } else if (record.glucose != null && glucoseRepository != null) {
      _openGlucoseRecord(glucoseRepository, existing: record);
    } else if (record.memo != null && widget.memoRepository != null) {
      _openMemoRecord(widget.memoRepository!, existing: record);
    } else if (record.type == DailyRecordType.food) {
      if (record.aiStatus == AiFoodStatus.analyzing) {
        showAppToast(context, '사진 속 음식을 분석하고 있어요.');
      } else {
        _openGlycemic(record);
      }
    } else {
      _notReady('기록 상세');
    }
  }

  /// MO-CAMERA-010 AI 음식 촬영
  void _openCamera() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (cameraContext) => FoodCameraScreen(
          onAnalyze: (file) async {
            final bytes = await file.readAsBytes();
            final card = await _runAiAnalysis(
              bytes,
              file.name,
              DateTime.now(),
            );
            // 분석 중 이탈했으면 오늘의 기록 카드로만 반영
            if (!cameraContext.mounted) return;
            Navigator.of(cameraContext).pop();
            if (card != null && mounted) await _openGlycemic(card);
          },
        ),
      ),
    );
  }

  /// MO-CHAT-010 따당챗 — 상단 탭 전환이라 애니메이션 없이 올림
  void _openChat() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (chatContext, _, _) => ChatScreen(
          onSelectHomeTab: () => Navigator.of(chatContext).pop(),
          onSelectDock: (tab) {
            Navigator.of(chatContext).pop();
            _onSelectDock(tab);
          },
        ),
      ),
    );
  }

  void _onSelectDock(HomeTab tab) {
    switch (tab) {
      case HomeTab.home:
        break;
      case HomeTab.camera:
        _openCamera();
      case HomeTab.myPage:
        _openMyPage();
      case HomeTab.farm:
        // 정책서에 농장 화면 없음 (1차 전달본 시안만 있음)
        _notReady(tab.label);
    }
  }

  /// COM-POP-11 일일카드
  Future<void> _openDailyCard() {
    final data = _data;
    final yesterday = data.date.subtract(const Duration(days: 1));
    return showDailyCardDialog(
      context,
      load:
          widget.loadDailyCard ??
          () async => DailyCardData.fromPoints(
            yesterday,
            const [],
            targetMin: data.targetMin,
            targetMax: data.targetMax,
          ),
    );
  }

  void _notReady(String feature) {
    showAppToast(context, '$feature 준비 중입니다.');
  }

  /// MO-MYPAGE-010 — 하단 탭 전환이라 애니메이션 없이 올림
  void _openMyPage() {
    final data = _data;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (context, _, _) => MyPageScreen(
          repository: _myPageRepository,
          sensor: SensorStatus.fromHome(
            connected: data.sensorConnected,
            day: data.sensorDay,
          ),
          onConnectSensor: _openAttach,
          onSelectTab: (tab) {
            switch (tab) {
              case HomeTab.home || HomeTab.myPage:
                Navigator.of(context).pop();
              case HomeTab.camera:
                Navigator.of(context).pop();
                _openCamera();
              case HomeTab.farm:
                showAppToast(context, '${tab.label} 준비 중입니다.');
            }
          },
          onLoggedOut: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const AppStart()),
            (_) => false,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      bottomNavigationBar: HomeDockBar(
        current: HomeTab.home,
        onSelect: _onSelectDock,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: _chartActive ? const NeverScrollableScrollPhysics() : null,
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
                          // 알림 창: 정책서 '미기획'
                          onTapNotification: () => _notReady('알림'),
                          onSelectTab: (tab) {
                            if (tab == HomeHeaderTab.chat) _openChat();
                          },
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
                        onConnect: _openAttach,
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
                        onTapDailyCard: _openDailyCard,
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
          child: SvgPicture.asset(
            'assets/home/plus.svg',
            width: 26,
            height: 26,
          ),
        ),
      ),
    );
  }
}
