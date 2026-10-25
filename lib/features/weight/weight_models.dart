import 'package:flutter/foundation.dart';

/// MO-WEIGHT-010 입력 규칙
abstract final class WeightPolicy {
  /// 유효 범위 (범위 밖은 스크롤 한계로 막힘)
  static const double minKg = 0;
  static const double maxKg = 200;

  /// 0.1kg 단위로 증감
  static const double stepKg = 0.1;

  /// 직전 저장값이 없을 때 시작값
  /// (MO-WEIGHT-010에 수치가 없어 MO-CURATION-010 몸무게 기본 포커스 60kg을 따름 — 확인 필요)
  static const double defaultStartKg = 60;

  /// 0.1kg 단위로 반올림하고 유효 범위 안으로 맞춤
  static double normalize(double kg) =>
      (kg.clamp(minKg, maxKg) * 10).round() / 10;
}

/// 체중 기록 한 건 (같은 날짜는 한 건만 유지)
@immutable
class WeightRecord {
  WeightRecord({required DateTime date, required double kg})
    : date = DateTime(date.year, date.month, date.day),
      kg = WeightPolicy.normalize(kg);

  /// 기록 일자 (시각 제외)
  final DateTime date;
  final double kg;

  @override
  bool operator ==(Object other) =>
      other is WeightRecord && other.date == date && other.kg == kg;

  @override
  int get hashCode => Object.hash(date, kg);
}

/// 체중 화면을 닫을 때 돌려주는 결과 (닫기·변경 없는 수정은 null)
@immutable
class WeightRecordResult {
  const WeightRecordResult.saved(WeightRecord this.record) : deleted = false;
  const WeightRecordResult.deleted() : record = null, deleted = true;

  /// 저장된 기록 (삭제면 null)
  final WeightRecord? record;
  final bool deleted;
}

/// 체중 저장소 (서버 API 가 준비되면 이 인터페이스를 구현해서 교체)
abstract class WeightRepository {
  /// 가장 최근에 저장한 기록
  Future<WeightRecord?> latest();

  /// 저장. 같은 날짜에 기록이 있으면 최신값으로 갱신
  Future<void> save(WeightRecord record);

  Future<void> delete(DateTime date);
}

/// 미리보기 / 테스트용 메모리 저장소
class SampleWeightRepository implements WeightRepository {
  final Map<DateTime, WeightRecord> _byDate = {};
  DateTime? _lastSaved;

  @override
  Future<WeightRecord?> latest() async =>
      _lastSaved == null ? null : _byDate[_lastSaved];

  @override
  Future<void> save(WeightRecord record) async {
    _byDate[record.date] = record;
    _lastSaved = record.date;
  }

  @override
  Future<void> delete(DateTime date) async {
    final key = DateTime(date.year, date.month, date.day);
    _byDate.remove(key);
    if (_lastSaved == key) _lastSaved = null;
  }
}
