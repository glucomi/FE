import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/features/drug/drug_models.dart';

/// BE adapter: member medications and medication record CRUD.
class ApiDrugRepository implements DrugRepository {
  ApiDrugRepository([ApiClient? client])
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const _base = '/api/members/me/medications';

  static String _category(DrugType type) => switch (type) {
    DrugType.diabetes => 'DIABETES',
    DrugType.hyperlipidemia => 'HYPERLIPIDEMIA',
    DrugType.hypertension => 'HYPERTENSION',
    DrugType.supplement => 'SUPPLEMENT',
    DrugType.other => 'ETC',
  };

  static DrugType _type(String category) => switch (category) {
    'DIABETES' => DrugType.diabetes,
    'HYPERLIPIDEMIA' => DrugType.hyperlipidemia,
    'HYPERTENSION' => DrugType.hypertension,
    'SUPPLEMENT' => DrugType.supplement,
    _ => DrugType.other,
  };

  SavedDrug _saved(Map<String, dynamic> json) => SavedDrug(
    id: '${json['memberMedicationId']}',
    type: _type(json['category'] as String),
    productName: json['productName'] as String?,
  );

  DrugRecord _record(Map<String, dynamic> json) => DrugRecord(
    id: '${json['medicationRecordId']}',
    memberMedicationId: '${json['memberMedicationId']}',
    type: _type(json['category'] as String),
    productName: json['productName'] as String?,
    time: parseApiDateTime(json['takenAt'] as String),
    memo: json['memo'] as String?,
  );

  @override
  Future<List<SavedDrug>> savedDrugs() async {
    final response = await _client.get(_base) as List<dynamic>;
    return [for (final item in response) _saved(item as Map<String, dynamic>)];
  }

  @override
  Future<SavedDrug> addSavedDrug({
    required DrugType type,
    String? productName,
  }) async {
    final response = await _client.post(
      _base,
      body: {'category': _category(type), 'productName': productName?.trim()},
    );
    return _saved(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteSavedDrug(String id) async {
    await _client.delete('$_base/$id');
  }

  @override
  Future<DrugRecord> saveRecord(DrugRecord record) async {
    final memberId = record.memberMedicationId;
    if (memberId == null) {
      throw const ApiException(message: '내 복용약에서 약을 선택해주세요.');
    }
    final body = {
      'memberMedicationId': int.parse(memberId),
      'takenAt': formatApiDateTime(record.time),
      'productName': record.productName,
      'memo': record.memo,
    };
    final response = record.id == null
        ? await _client.post('/api/medication-records', body: body)
        : await _client.put('/api/medication-records/${record.id}', body: body);
    return _record(response as Map<String, dynamic>);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _client.delete('/api/medication-records/$id');
  }

  Future<List<DrugRecord>> byDate(DateTime day) async {
    final response = await _client.get(
      '/api/medication-records',
      query: {'date': formatApiDate(day)},
    ) as List<dynamic>;
    return [for (final item in response) _record(item as Map<String, dynamic>)];
  }
}
