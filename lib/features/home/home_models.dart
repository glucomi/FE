import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// CGM(연속혈당측정) 한 개의 측정값
@immutable
class CgmPoint {
  const CgmPoint({required this.time, required this.value});

  final DateTime time;
  final double value;
}

/// 오늘의 기록 종류 (Figma Chip/Memo)
enum DailyRecordType {
  food('음식', 'assets/home/memo_food.svg', AppColors.statusWarning),
  weight('체중', 'assets/home/memo_weight.svg', AppColors.green500),
  insulin('인슐린', 'assets/home/memo_insulin.svg', AppColors.blue400),
  medicine('복약', 'assets/home/memo_medicine.svg', AppColors.purple400),
  memo('메모', 'assets/home/memo_note.svg', AppColors.gray500),
  exercise('운동', 'assets/home/memo_exercise.svg', AppColors.gray700);

  const DailyRecordType(this.label, this.iconAsset, this.color);

  final String label;
  final String iconAsset;
  final Color color;

  Color get tint => color.withValues(alpha: 0.1);
}

/// 오늘의 기록 카드 한 장
@immutable
class DailyRecord {
  const DailyRecord({
    required this.time,
    required this.type,
    required this.title,
    this.details = const [],
    this.carbsGram,
    this.imageAsset,
  });

  final DateTime time;
  final DailyRecordType type;
  final String title;

  /// 제목 아래 회색 보조 정보 (구분선으로 나뉨) 예: ['128 kcal', '탄수화물 20 g']
  final List<String> details;

  /// 음식 기록의 탄수화물 (홈 요약 합계에 사용)
  final double? carbsGram;

  /// 음식 사진 (없으면 음식 아이콘 표시)
  final String? imageAsset;
}

/// 홈 화면에 필요한 데이터
@immutable
class HomeData {
  const HomeData({
    required this.date,
    required this.sensorConnected,
    this.sensorDay,
    this.points = const [],
    this.records = const [],
    this.targetMin,
    this.targetMax,
    this.dailyScores = const {},
  });

  /// 큐레이션 직후처럼 센서 연결 전 상태
  factory HomeData.empty({DateTime? date, int? targetMin, int? targetMax}) =>
      HomeData(
        date: date ?? DateTime.now(),
        sensorConnected: false,
        targetMin: targetMin,
        targetMax: targetMax,
      );

  final DateTime date;
  final bool sensorConnected;

  /// 센서 부착 N일차
  final int? sensorDay;
  final List<CgmPoint> points;
  final List<DailyRecord> records;
  final int? targetMin;
  final int? targetMax;

  /// 지난 날짜별 혈당 점수 (자정 기준 날짜 키) — 달력 표시용
  final Map<DateTime, int> dailyScores;

  /// 달력에 표시할 점수 (오늘은 현재 데이터로 계산한 점수)
  Map<DateTime, int> get calendarScores {
    return {
      ...dailyScores,
      DateTime(date.year, date.month, date.day): ?score,
    };
  }

  /// 기록을 덧붙인 새 데이터 (시간순 정렬)
  HomeData withAddedRecords(List<DailyRecord> added) {
    if (added.isEmpty) return this;
    return HomeData(
      date: date,
      sensorConnected: sensorConnected,
      sensorDay: sensorDay,
      points: points,
      records: [...records, ...added]
        ..sort((a, b) => a.time.compareTo(b.time)),
      targetMin: targetMin,
      targetMax: targetMax,
      dailyScores: dailyScores,
    );
  }

  bool get hasGlucose => points.isNotEmpty;

  /// 그래프 색 기준 (목표 범위가 없으면 70-140)
  int get rangeMin => targetMin ?? 70;
  int get rangeMax => targetMax ?? 140;

  double? get minGlucose =>
      hasGlucose ? points.map((p) => p.value).reduce(math.min) : null;

  double? get maxGlucose =>
      hasGlucose ? points.map((p) => p.value).reduce(math.max) : null;

  double? get averageGlucose => hasGlucose
      ? points.map((p) => p.value).reduce((a, b) => a + b) / points.length
      : null;

  /// 목표 범위 안에 있던 비율(%) — 혈당 점수로 사용 (추후 서버 계산값으로 교체)
  int? get score {
    if (!hasGlucose) return null;
    final inRange = points
        .where((p) => p.value >= rangeMin && p.value <= rangeMax)
        .length;
    return (inRange / points.length * 100).round();
  }

  /// 목표 상한을 넘어선 횟수
  int? get spikeCount {
    if (!hasGlucose) return null;
    var count = 0;
    for (var i = 1; i < points.length; i++) {
      if (points[i - 1].value <= rangeMax && points[i].value > rangeMax) {
        count++;
      }
    }
    return count;
  }

  /// 음식 기록 탄수화물 합계
  double? get carbsGram {
    final foods = records.where((r) => r.carbsGram != null);
    if (foods.isEmpty) return null;
    return foods.map((r) => r.carbsGram!).reduce((a, b) => a + b);
  }

  /// Figma 예시와 비슷한 미리보기용 데이터
  factory HomeData.sample({DateTime? today}) {
    final now = today ?? DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    DateTime at(int h, int m) => day.add(Duration(hours: h, minutes: m));

    // 그래프 테스트 화면(GraphTestScreen)과 같은 측정값
    const samples = <(int, int, double)>[
      (8, 30, 128), (8, 45, 115), (9, 0, 118), (9, 15, 92), (9, 35, 94),
      (9, 50, 78), (10, 5, 82), (10, 20, 76), (10, 40, 110), (10, 55, 175),
      (11, 10, 133), (11, 30, 122), (11, 50, 108), (12, 5, 142), (12, 20, 146),
      (12, 35, 125), (12, 55, 105), (13, 10, 98), (13, 25, 113),
    ];
    final points = [
      for (final (h, m, v) in samples) CgmPoint(time: at(h, m), value: v),
    ];

    // 며칠 전 → 점수 (비어 있는 날은 기록 없음)
    const pastScores = {
      1: 72, 2: 68, 3: 56, 4: 45, 5: 70, 6: 74, 8: 54, 9: 90, 10: 50,
      11: 72, 12: 68, 15: 70, 16: 56, 17: 74, 18: 72, 20: 48, 22: 66,
    };

    return HomeData(
      date: day,
      sensorConnected: true,
      sensorDay: 1,
      targetMin: 70,
      targetMax: 140,
      points: points,
      dailyScores: {
        for (final MapEntry(key: ago, value: v) in pastScores.entries)
          DateTime(day.year, day.month, day.day - ago): v,
      },
      records: [
        DailyRecord(
          time: at(11, 4),
          type: DailyRecordType.food,
          title: '짜장면 외 3개',
          details: const ['총 128 kcal', '총 탄수화물 20 g'],
          carbsGram: 20,
        ),
        DailyRecord(
          time: at(11, 40),
          type: DailyRecordType.weight,
          title: '47.7 kg',
        ),
        DailyRecord(
          time: at(11, 43),
          type: DailyRecordType.insulin,
          title: '레버미어플렉스펜주',
          details: const ['장기형', '1U'],
        ),
        DailyRecord(
          time: at(14, 10),
          type: DailyRecordType.medicine,
          title: '다이어트 한방약',
          details: const ['다한방'],
        ),
        DailyRecord(
          time: at(16, 30),
          type: DailyRecordType.memo,
          title: '오늘은 몸이 무거운느낌이라 저혈당 체크를 자주 해야겠다',
        ),
        DailyRecord(
          time: at(16, 35),
          type: DailyRecordType.exercise,
          title: '빨리 걷기',
          details: const ['20 분', '100 kcal'],
        ),
      ],
    );
  }
}

/// 오전 11시 04분 / 오후 14시 10분 (Figma 표기 그대로 24시간제 시각 사용)
String formatRecordTime(DateTime time) {
  final period = time.hour < 12 ? '오전' : '오후';
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$period $hour시 $minute분';
}
