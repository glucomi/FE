import 'package:flutter/foundation.dart';

/// 복용약 종류 (MO-DRUG-020 / COM-POP-09)
enum DrugType {
  diabetes('당뇨약'),
  hyperlipidemia('고지혈증약'),
  hypertension('고혈압약'),
  supplement('영양제'),
  other('약(기타)');

  const DrugType(this.label);

  final String label;
}

abstract final class DrugPolicy {
  /// MO-DRUG-020: 제품명 최대 길이 (넘는 입력은 잘라냄)
  static const int productNameMaxLength = 20;

  /// MO-DRUG-010 메모 (COM-04)
  static const int memoMaxLength = 1000;
}

/// 내 복용약 (MO-DRUG-020 에서 등록, 030 에서 관리)
@immutable
class SavedDrug {
  const SavedDrug({required this.id, required this.type, this.productName});

  final String id;
  final DrugType type;

  /// 선택 항목 (없으면 null)
  final String? productName;

  @override
  bool operator ==(Object other) =>
      other is SavedDrug &&
      other.id == id &&
      other.type == type &&
      other.productName == productName;

  @override
  int get hashCode => Object.hash(id, type, productName);
}

/// 복약 기록 한 건 (MO-DRUG-010)
@immutable
class DrugRecord {
  const DrugRecord({
    this.id,
    required this.time,
    required this.type,
    this.memberMedicationId,
    this.productName,
    this.memo,
  });

  /// 저장 전이면 null
  final String? id;

  /// 복용 일시 (날짜 + 시간)
  final DateTime time;
  final DrugType type;
  final String? memberMedicationId;
  final String? productName;
  final String? memo;

  /// 오늘의 기록 카드 제목: 약 종류 · 제품명
  String get title {
    final name = productName;
    return name == null || name.isEmpty ? type.label : '${type.label} · $name';
  }

  DrugRecord copyWith({String? id}) => DrugRecord(
    id: id ?? this.id,
    time: time,
    type: type,
    memberMedicationId: memberMedicationId,
    productName: productName,
    memo: memo,
  );

  @override
  bool operator ==(Object other) =>
      other is DrugRecord &&
      other.id == id &&
      other.time == time &&
      other.type == type &&
      other.memberMedicationId == memberMedicationId &&
      other.productName == productName &&
      other.memo == memo;

  @override
  int get hashCode =>
      Object.hash(id, time, type, memberMedicationId, productName, memo);
}

/// 복약 화면을 닫을 때 돌려주는 결과 (닫기·변경 없는 수정은 null)
@immutable
class DrugRecordResult {
  const DrugRecordResult.saved(DrugRecord this.record) : deleted = false;
  const DrugRecordResult.deleted() : record = null, deleted = true;

  /// 저장된 기록 (삭제면 null)
  final DrugRecord? record;
  final bool deleted;
}

/// 복약 저장소 (서버 API 가 준비되면 이 인터페이스를 구현해서 교체)
abstract class DrugRepository {
  /// 내 복용약 목록 (등록 순)
  Future<List<SavedDrug>> savedDrugs();

  /// 내 복용약 등록. 같은 약 종류·제품명이 있어도 별도 처리 없이 추가
  Future<SavedDrug> addSavedDrug({required DrugType type, String? productName});

  Future<void> deleteSavedDrug(String id);

  /// 복약 기록 저장 (id 가 있으면 수정)
  Future<DrugRecord> saveRecord(DrugRecord record);

  Future<void> deleteRecord(String id);
}

/// 미리보기 / 테스트용 메모리 저장소
class SampleDrugRepository implements DrugRepository {
  SampleDrugRepository({List<SavedDrug> initial = const []})
    : _saved = [...initial];

  final List<SavedDrug> _saved;
  final Map<String, DrugRecord> _records = {};
  int _seq = 0;

  String _nextId(String prefix) => '$prefix-${++_seq}';

  @override
  Future<List<SavedDrug>> savedDrugs() async => List.unmodifiable(_saved);

  @override
  Future<SavedDrug> addSavedDrug({
    required DrugType type,
    String? productName,
  }) async {
    final name = productName?.trim();
    final drug = SavedDrug(
      id: _nextId('drug'),
      type: type,
      productName: name == null || name.isEmpty ? null : name,
    );
    _saved.add(drug);
    return drug;
  }

  @override
  Future<void> deleteSavedDrug(String id) async =>
      _saved.removeWhere((d) => d.id == id);

  @override
  Future<DrugRecord> saveRecord(DrugRecord record) async {
    final saved = record.id == null
        ? record.copyWith(id: _nextId('record'))
        : record;
    _records[saved.id!] = saved;
    return saved;
  }

  @override
  Future<void> deleteRecord(String id) async => _records.remove(id);
}
