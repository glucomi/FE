import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/features/home/home_models.dart';

class HomeApi {
  HomeApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// 달력에 한 번에 불러올 수 있는 최대 일수 (서버 제한)
  static const int maxScoreDays = 42;

  /// GET /api/home — 선택한 날짜의 센서·그래프·요약·식사
  Future<HomeData> fetch(
    DateTime date, {
    Map<DateTime, int> dailyScores = const {},
  }) async {
    final json =
        await _client.get('/api/home', query: {'date': formatApiDate(date)})
            as Map<String, dynamic>;

    final sensor = json['sensor'] as Map<String, dynamic>? ?? const {};
    final range = json['targetRange'] as Map<String, dynamic>?;
    final graph = json['graph'] as Map<String, dynamic>? ?? const {};
    final summary = json['summary'] as Map<String, dynamic>? ?? const {};
    final meals = json['meals'] as List<dynamic>? ?? const [];

    final points = <CgmPoint>[
      for (final p in graph['points'] as List<dynamic>? ?? const [])
        if ((p as Map<String, dynamic>)['value'] != null)
          CgmPoint(
            time: parseApiDateTime(p['time'] as String),
            value: asDouble(p['value'])!,
          ),
    ]..sort((a, b) => a.time.compareTo(b.time));

    return HomeData(
      date: json['date'] is String
          ? DateTime.parse(json['date'] as String)
          : DateTime(date.year, date.month, date.day),
      sensorConnected: sensor['connected'] == true,
      sensorDay: asInt(sensor['sensorDay']),
      targetMin: asInt(range?['min']),
      targetMax: asInt(range?['max']),
      points: points,
      records: [
        for (final m in meals) _mealRecord(m as Map<String, dynamic>),
      ]..sort((a, b) => a.time.compareTo(b.time)),
      dailyScores: dailyScores,
      summary: HomeSummary(
        score: asInt(summary['glucoseScore']),
        scoreStatus: summary['glucoseScoreStatus'] as String?,
        minGlucose: asInt(graph['minGlucose']),
        maxGlucose: asInt(summary['maxGlucose']) ?? asInt(graph['maxGlucose']),
        averageGlucose: asInt(summary['averageGlucose']),
        spikeCount: asInt(summary['spikeCount']),
        carbsGram: asDouble(summary['carbohydrateG']),
      ),
    );
  }

  /// GET /api/glucose/daily-scores — 점수가 있는 날만 담아서 돌려줌
  Future<Map<DateTime, int>> dailyScores(DateTime from, DateTime to) async {
    final list =
        await _client.get(
              '/api/glucose/daily-scores',
              query: {'from': formatApiDate(from), 'to': formatApiDate(to)},
            )
            as List<dynamic>;
    return {
      for (final item in list)
        if ((item as Map<String, dynamic>)['score'] != null)
          DateTime.parse(item['date'] as String): asInt(item['score'])!,
    };
  }

  DailyRecord _mealRecord(Map<String, dynamic> m) {
    final name = m['representativeFoodName'] as String? ?? '식사';
    final count = asInt(m['itemCount']) ?? 1;
    final kcal = asDouble(m['kcal']) ?? 0;
    final carbs = asDouble(m['carbohydrateG']) ?? 0;
    return DailyRecord(
      time: parseApiDateTime(m['eatenAt'] as String),
      type: DailyRecordType.food,
      title: count > 1 ? '$name 외 ${count - 1}개' : name,
      details: ['총 ${kcal.round()} kcal', '총 탄수화물 ${carbs.round()} g'],
      carbsGram: carbs.roundToDouble(),
    );
  }
}
