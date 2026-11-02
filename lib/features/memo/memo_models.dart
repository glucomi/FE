import 'package:flutter/foundation.dart';

/// MO-MEMO-010 입력 규칙
abstract final class MemoPolicy {
  /// 메모 최대 길이 (COM-04: 최대 1000자, 0/1000 실시간 표시)
  static const int maxLength = 1000;

  /// 첨부 사진 최대 장수
  /// (정책서에 수치가 없어 COM-06 디자인의 '1/10' 표기를 따름 — 확인 필요)
  static const int maxPhotos = 10;

  /// 사진 혹은 텍스트가 하나라도 입력되면 저장 가능
  /// (공백만 입력한 경우는 입력 없음으로 봄 — 확인 필요)
  static bool canSave({required String text, required int photoCount}) =>
      text.trim().isNotEmpty || photoCount > 0;
}

/// 첨부한 사진 한 장 (웹·앱 모두 바이트로 들고 있음)
@immutable
class MemoPhoto {
  const MemoPhoto(this.bytes, {this.name});

  final Uint8List bytes;
  final String? name;
}

/// 메모 기록 한 건
@immutable
class MemoRecord {
  MemoRecord({
    this.id,
    required DateTime time,
    this.text = '',
    List<MemoPhoto> photos = const [],
  }) : time = DateTime(time.year, time.month, time.day, time.hour, time.minute),
       photos = List.unmodifiable(photos);

  /// 저장소가 붙여주는 식별자 (저장 전에는 null)
  final String? id;

  /// 기록 일시 (분 단위)
  final DateTime time;
  final String text;
  final List<MemoPhoto> photos;

  MemoRecord copyWith({String? id}) =>
      MemoRecord(id: id ?? this.id, time: time, text: text, photos: photos);

  /// 날짜·시간·내용·사진이 모두 같은지 (수정 시 변경 여부 확인용)
  bool sameContentAs(MemoRecord other) =>
      other.time == time &&
      other.text == text &&
      listEquals(other.photos, photos);
}

/// 메모 화면을 닫을 때 돌려주는 결과 (닫기·변경 없는 수정은 null)
@immutable
class MemoRecordResult {
  const MemoRecordResult.saved(MemoRecord this.record) : deleted = false;
  const MemoRecordResult.deleted() : record = null, deleted = true;

  /// 저장된 기록 (삭제면 null)
  final MemoRecord? record;
  final bool deleted;
}

/// 메모 저장소 (서버에 메모 API 가 생기면 이 인터페이스를 구현해서 교체)
abstract class MemoRepository {
  /// 저장. id 가 있으면 해당 기록을 갱신하고, 저장된 기록(id 포함)을 돌려줌
  Future<MemoRecord> save(MemoRecord record);

  Future<void> delete(String id);
}

/// 미리보기 / 서버 연동 전 메모리 저장소
class SampleMemoRepository implements MemoRepository {
  final Map<String, MemoRecord> _byId = {};
  int _nextId = 1;

  List<MemoRecord> get records => _byId.values.toList(growable: false);

  @override
  Future<MemoRecord> save(MemoRecord record) async {
    final saved = record.id == null
        ? record.copyWith(id: 'memo-${_nextId++}')
        : record;
    _byId[saved.id!] = saved;
    return saved;
  }

  @override
  Future<void> delete(String id) async => _byId.remove(id);
}
