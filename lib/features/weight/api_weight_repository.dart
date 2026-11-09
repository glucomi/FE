import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/features/weight/weight_models.dart';

/// 서버 체중 API 저장소 (/api/weight-records)
///
/// 하루에 한 건만 저장되고, 같은 날짜로 다시 저장하면 최신값으로 갱신됨
class ApiWeightRepository implements WeightRepository {
  ApiWeightRepository([ApiClient? client])
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const _base = '/api/weight-records';

  WeightRecord? _fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final kg = asDouble(json['weightKg']);
    if (kg == null) return null;
    return WeightRecord(date: DateTime.parse(json['date'] as String), kg: kg);
  }

  @override
  Future<WeightRecord?> latest() async =>
      _fromJson(await _client.get('$_base/latest'));

  /// 해당 날짜 기록 (없으면 null)
  Future<WeightRecord?> byDate(DateTime date) async =>
      _fromJson(await _client.get('$_base/${formatApiDate(date)}'));

  @override
  Future<void> save(WeightRecord record) async {
    await _client.put(
      '$_base/${formatApiDate(record.date)}',
      body: {'weightKg': record.kg},
    );
  }

  @override
  Future<void> delete(DateTime date) async {
    await _client.delete('$_base/${formatApiDate(date)}');
  }
}
