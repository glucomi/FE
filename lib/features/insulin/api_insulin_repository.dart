import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';

/// 서버 인슐린 API 저장소
///
/// - GET /api/insulin-products (COM-POP-08 목록)
/// - /api/members/me/insulins (내 인슐린, MO-INSULIN-020/030)
/// - /api/insulin-records (투여 기록, MO-INSULIN-010)
///
/// BE 브랜치 feat/record-33-insulin-record 기준 계약
class ApiInsulinRepository implements InsulinRepository {
  ApiInsulinRepository([ApiClient? client])
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const _mine = '/api/members/me/insulins';
  static const _records = '/api/insulin-records';

  List<InsulinProduct>? _products;

  /// 서버 작용 유형 → 화면 분류 (서버에는 '복합형'이 없음)
  static InsulinCategory _category(String? type) => switch (type) {
    'RAPID' => InsulinCategory.rapidActing,
    'SHORT' => InsulinCategory.shortActing,
    'INTERMEDIATE' => InsulinCategory.intermediate,
    'LONG' => InsulinCategory.longActing,
    _ => InsulinCategory.premixed,
  };

  InsulinProduct _product(Map<String, dynamic> json) => InsulinProduct(
    json['name'] as String? ?? '',
    _category(json['actionType'] as String?),
    id: json['insulinProductId'] == null ? null : '${json['insulinProductId']}',
  );

  MyInsulin _my(Map<String, dynamic> json) => MyInsulin(
    id: '${json['memberInsulinId']}',
    product: _product(json),
    dose: asDouble(json['defaultDoseUnit']) ?? 0,
  );

  InsulinRecord _record(Map<String, dynamic> json) => InsulinRecord(
    id: '${json['insulinRecordId']}',
    time: parseApiDateTime(json['injectedAt'] as String),
    product: _product(json),
    dose: asDouble(json['doseUnit']) ?? 0,
    memo: json['memo'] as String? ?? '',
    memberInsulinId: '${json['memberInsulinId']}',
  );

  @override
  Future<List<InsulinProduct>> products() async {
    final cached = _products;
    if (cached != null) return cached;
    final list = await _client.get('/api/insulin-products') as List<dynamic>;
    return _products = [
      for (final item in list) _product(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<List<MyInsulin>> myInsulins() async {
    final list = await _client.get(_mine) as List<dynamic>;
    return [for (final item in list) _my(item as Map<String, dynamic>)];
  }

  @override
  Future<MyInsulin> addMyInsulin(InsulinProduct product, double dose) async {
    var productId = product.id;
    if (productId == null) {
      final match = (await products()).where((p) => p == product).firstOrNull;
      productId = match?.id;
    }
    if (productId == null) {
      throw const ApiException(message: '인슐린 제품을 다시 선택해주세요.');
    }
    try {
      final json = await _client.post(
        _mine,
        body: {
          'insulinProductId': int.tryParse(productId) ?? productId,
          'defaultDoseUnit': dose,
        },
      );
      return _my(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      // 409 INSULIN_4090: 이미 등록한 제품 → COM-TOAST-02
      if (e.statusCode == 409) throw DuplicateInsulinException(product);
      rethrow;
    }
  }

  @override
  Future<void> deleteMyInsulin(String id) async {
    await _client.delete('$_mine/$id');
  }

  Future<List<InsulinRecord>> byDate(DateTime day) async {
    final list = await _client.get(
      _records,
      query: {'date': formatApiDate(day)},
    ) as List<dynamic>;
    return [for (final item in list) _record(item as Map<String, dynamic>)];
  }

  @override
  Future<InsulinRecord> saveRecord(InsulinRecord record) async {
    final memberInsulinId = record.memberInsulinId;
    if (memberInsulinId == null) {
      throw const ApiException(message: '내 인슐린에서 인슐린을 선택해주세요.');
    }
    final body = {
      'memberInsulinId': int.tryParse(memberInsulinId) ?? memberInsulinId,
      'injectedAt': formatApiDateTime(record.time),
      'doseUnit': record.dose,
      'memo': record.memo.trim().isEmpty ? null : record.memo.trim(),
    };
    final json = record.id == null
        ? await _client.post(_records, body: body)
        : await _client.put('$_records/${record.id}', body: body);
    return _record(json as Map<String, dynamic>);
  }

  @override
  Future<void> deleteRecord(String id) async {
    await _client.delete('$_records/$id');
  }
}
