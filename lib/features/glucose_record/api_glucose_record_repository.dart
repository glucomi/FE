import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/features/glucose_record/glucose_record_models.dart';

/// REST adapter for BE: GET/POST/PUT/DELETE /api/glucose-records.
/// No sensitive health data is written to unencrypted device preferences.
class ApiGlucoseRecordRepository implements GlucoseRecordRepository {
  ApiGlucoseRecordRepository([ApiClient? client])
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  Future<List<GlucoseRecord>> byDate(DateTime day) async {
    final response = await _client.get(
      '/api/glucose-records',
      query: {'date': formatApiDate(day)},
    ) as List<dynamic>;
    return [
      for (final item in response) _fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<GlucoseRecord> save(GlucoseRecord record) async {
    if (!GlucosePolicy.isValid(record.mgDl)) {
      throw const ApiException(message: '혈당은 10~300 mg/dL 범위로 입력해주세요');
    }
    final body = <String, dynamic>{
      'measuredAt': formatApiDateTime(record.time),
      'valueMgDl': record.mgDl,
      'memo': record.memo,
    };
    final response = record.id == null
        ? await _client.post('/api/glucose-records', body: body)
        : await _client.put('/api/glucose-records/${record.id}', body: body);
    return _fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete('/api/glucose-records/$id');
  }

  GlucoseRecord _fromJson(Map<String, dynamic> json) => GlucoseRecord(
    id: '${json['glucoseRecordId']}',
    time: parseApiDateTime(json['measuredAt'] as String),
    mgDl: asInt(json['valueMgDl'])!,
    memo: json['memo'] as String? ?? '',
  );
}
