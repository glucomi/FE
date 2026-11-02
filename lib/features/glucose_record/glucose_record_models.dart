import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// MO-GLUCOSER-010 입력 규칙
///
/// 정책서(GLUCOSER-010)에 기능설명이 비어 있어서 범위·단위는 임시값 — 확인 필요
abstract final class GlucosePolicy {
  /// 저장 가능한 범위 (mg/dL, 정수)
  static const int minMgDl = 20;
  static const int maxMgDl = 600;

  /// 정수부 최대 자릿수
  static const int maxDigits = 3;

  /// 메모 최대 글자 수 (COM-04)
  static const int memoMaxLength = 1000;

  static bool isValid(int? mgDl) =>
      mgDl != null && mgDl >= minMgDl && mgDl <= maxMgDl;
}

/// 혈당값 입력 정리
///
/// - 숫자만, 정수만 (소수점 차단)
/// - 선행 0 정리 ("012" → "12", "0" → 빈 값)
/// - 3자리 / 최대값(600) 초과 입력은 막아서 직전 값 유지
class GlucoseValueInputFormatter extends TextInputFormatter {
  const GlucoseValueInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final trimmed = digits.replaceFirst(RegExp(r'^0+'), '');
    if (trimmed.length > GlucosePolicy.maxDigits ||
        (trimmed.isNotEmpty && int.parse(trimmed) > GlucosePolicy.maxMgDl)) {
      return oldValue;
    }
    if (trimmed == newValue.text) return newValue;
    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }
}

/// 혈당 직접 기록 한 건 (하루에 여러 건 가능)
@immutable
class GlucoseRecord {
  GlucoseRecord({
    this.id,
    required DateTime time,
    required this.mgDl,
    this.memo = '',
  }) : time = DateTime(time.year, time.month, time.day, time.hour, time.minute);

  /// 저장소가 붙여 준 id (저장 전이면 null)
  final String? id;

  /// 측정 일시 (분 단위)
  final DateTime time;
  final int mgDl;
  final String memo;

  GlucoseRecord copyWith({String? id}) =>
      GlucoseRecord(id: id ?? this.id, time: time, mgDl: mgDl, memo: memo);

  /// id 를 빼고 내용이 같은지 (수정 시 변화 없음 판단)
  bool sameContent(GlucoseRecord other) =>
      other.time == time && other.mgDl == mgDl && other.memo == memo;

  @override
  bool operator ==(Object other) =>
      other is GlucoseRecord && other.id == id && sameContent(other);

  @override
  int get hashCode => Object.hash(id, time, mgDl, memo);
}

/// 혈당 화면을 닫을 때 돌려주는 결과 (닫기·변경 없는 수정은 null)
@immutable
class GlucoseRecordResult {
  const GlucoseRecordResult.saved(GlucoseRecord this.record) : deleted = false;
  const GlucoseRecordResult.deleted() : record = null, deleted = true;

  /// 저장된 기록 (삭제면 null)
  final GlucoseRecord? record;
  final bool deleted;
}

/// 혈당 기록 저장소 (서버에 혈당 직접 기록 API 가 생기면 이 인터페이스를 구현해서 교체)
abstract class GlucoseRecordRepository {
  /// id 가 없으면 새로 저장, 있으면 그 기록을 수정. 저장된 기록(id 포함)을 돌려줌
  Future<GlucoseRecord> save(GlucoseRecord record);

  Future<void> delete(String id);
}

/// 미리보기 / 테스트용 메모리 저장소
class SampleGlucoseRecordRepository implements GlucoseRecordRepository {
  final Map<String, GlucoseRecord> _byId = {};
  int _seq = 0;

  List<GlucoseRecord> get records => List.unmodifiable(_byId.values);

  @override
  Future<GlucoseRecord> save(GlucoseRecord record) async {
    final saved = record.id == null
        ? record.copyWith(id: 'local-${++_seq}')
        : record;
    _byId[saved.id!] = saved;
    return saved;
  }

  @override
  Future<void> delete(String id) async => _byId.remove(id);
}
