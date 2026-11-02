import 'package:flutter/foundation.dart';

/// MO-EXERCISE-010 / 020 입력 규칙
abstract final class ExercisePolicy {
  /// 운동 시간 기본 시작값 (분)
  static const int defaultMinutes = 30;

  /// 운동 시간 입력 최대 자릿수 (정책에 상한이 없어 999분까지만 받음 — 확인 필요)
  static const int maxMinuteDigits = 3;

  /// 운동 목록의 칼로리 기준 시간 (65kcal / 30분)
  static const int baseMinutes = 30;

  /// 운동명 검색어 최대 길이
  static const int maxQueryLength = 20;

  /// 최근 기록한 운동 최대 노출 개수
  static const int maxRecent = 4;

  /// 메모 최대 길이 (COM-04)
  static const int maxMemoLength = 1000;
}

/// 운동 DB 의 운동 한 종류
@immutable
class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.kcalPerBase,
  });

  final String id;
  final String name;

  /// [ExercisePolicy.baseMinutes] 동안 소모 칼로리
  final int kcalPerBase;

  /// [minutes] 분 동안 소모 칼로리 (시간 비례, 반올림)
  int kcalFor(int minutes) =>
      (kcalPerBase * minutes / ExercisePolicy.baseMinutes).round();

  @override
  bool operator ==(Object other) => other is Exercise && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 기록에 추가된 운동 항목 (운동 + 수행 시간)
@immutable
class ExerciseEntry {
  const ExerciseEntry({required this.exercise, required this.minutes});

  final Exercise exercise;

  /// 0 이면 미입력(빈 값) 상태
  final int minutes;

  int get kcal => exercise.kcalFor(minutes);

  bool get isValid => minutes > 0;

  ExerciseEntry copyWith({int? minutes}) =>
      ExerciseEntry(exercise: exercise, minutes: minutes ?? this.minutes);

  @override
  bool operator ==(Object other) =>
      other is ExerciseEntry &&
      other.exercise == exercise &&
      other.minutes == minutes;

  @override
  int get hashCode => Object.hash(exercise, minutes);
}

/// 운동 기록 한 건
@immutable
class ExerciseRecord {
  ExerciseRecord({
    this.id,
    required DateTime time,
    required List<ExerciseEntry> entries,
    this.memo = '',
  }) : time = DateTime(time.year, time.month, time.day, time.hour, time.minute),
       entries = List.unmodifiable(entries);

  /// 저장 전이면 null
  final String? id;

  /// 기록 일시 (분 단위)
  final DateTime time;
  final List<ExerciseEntry> entries;
  final String memo;

  int get totalMinutes => entries.fold(0, (sum, e) => sum + e.minutes);
  int get totalKcal => entries.fold(0, (sum, e) => sum + e.kcal);

  /// 오늘의 기록 카드 제목 (예: 걷기 / 걷기 외 1개)
  String get title {
    if (entries.isEmpty) return '운동';
    final first = entries.first.exercise.name;
    return entries.length == 1 ? first : '$first 외 ${entries.length - 1}개';
  }

  ExerciseRecord copyWith({String? id}) =>
      ExerciseRecord(id: id ?? this.id, time: time, entries: entries, memo: memo);

  /// 저장할 내용이 같은지 (id 제외)
  bool sameContentAs(ExerciseRecord other) =>
      other.time == time &&
      other.memo == memo &&
      listEquals(other.entries, entries);
}

/// 운동 화면을 닫을 때 돌려주는 결과 (닫기·변경 없는 수정은 null)
@immutable
class ExerciseRecordResult {
  const ExerciseRecordResult.saved(ExerciseRecord this.record)
    : deleted = false;
  const ExerciseRecordResult.deleted() : record = null, deleted = true;

  final ExerciseRecord? record;
  final bool deleted;
}

/// 운동 DB · 기록 저장소 (서버 API 가 준비되면 이 인터페이스를 구현해서 교체)
abstract class ExerciseRepository {
  /// 전체 운동 목록 (가나다순)
  Future<List<Exercise>> catalog();

  /// 운동명 부분 일치 검색 (가나다순)
  Future<List<Exercise>> search(String query);

  /// 인기 운동 (가나다순)
  Future<List<Exercise>> popular();

  /// 최근 기록한 운동 (최근 기록 순, 같은 운동은 1건, 최대 4개)
  Future<List<Exercise>> recent();

  /// 저장 후 id 가 채워진 기록을 돌려줌. 같은 id 면 갱신
  Future<ExerciseRecord> save(ExerciseRecord record);

  Future<void> delete(String id);
}

int _byName(Exercise a, Exercise b) => a.name.compareTo(b.name);

/// 미리보기 / 테스트용 메모리 저장소
///
/// 운동 목록과 30분 칼로리는 서버 DB 가 나오기 전까지 쓰는 임시값
/// (걷기 65kcal 만 디자인 값 — 나머지는 확인 필요)
class SampleExerciseRepository implements ExerciseRepository {
  SampleExerciseRepository({List<Exercise>? exercises})
    : _catalog = [...(exercises ?? sampleExercises)]..sort(_byName);

  static const List<Exercise> sampleExercises = [
    Exercise(id: 'walk', name: '걷기', kcalPerBase: 65),
    Exercise(id: 'run', name: '달리기', kcalPerBase: 240),
    Exercise(id: 'cycle', name: '자전거 타기', kcalPerBase: 180),
    Exercise(id: 'swim', name: '수영', kcalPerBase: 210),
    Exercise(id: 'hike', name: '등산', kcalPerBase: 200),
    Exercise(id: 'stairs', name: '계단 오르기', kcalPerBase: 120),
    Exercise(id: 'yoga', name: '요가', kcalPerBase: 75),
    Exercise(id: 'pilates', name: '필라테스', kcalPerBase: 90),
    Exercise(id: 'stretch', name: '스트레칭', kcalPerBase: 70),
    Exercise(id: 'weight', name: '근력 운동', kcalPerBase: 105),
    Exercise(id: 'rope', name: '줄넘기', kcalPerBase: 300),
    Exercise(id: 'badminton', name: '배드민턴', kcalPerBase: 165),
  ];

  /// 인기 운동은 아직 미확정이라 임시로 고른 목록
  static const Set<String> _popularIds = {'walk', 'run', 'cycle'};

  final List<Exercise> _catalog;
  final Map<String, ExerciseRecord> _records = {};
  int _seq = 0;

  @override
  Future<List<Exercise>> catalog() async => List.unmodifiable(_catalog);

  @override
  Future<List<Exercise>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return const [];
    return [
      for (final e in _catalog)
        if (e.name.contains(q)) e,
    ];
  }

  @override
  Future<List<Exercise>> popular() async => [
    for (final e in _catalog)
      if (_popularIds.contains(e.id)) e,
  ];

  @override
  Future<List<Exercise>> recent() async {
    final records = _records.values.toList()
      ..sort((a, b) => b.time.compareTo(a.time));
    final seen = <Exercise>{};
    for (final r in records) {
      for (final entry in r.entries) {
        if (seen.add(entry.exercise) && seen.length == ExercisePolicy.maxRecent) {
          return seen.toList();
        }
      }
    }
    return seen.toList();
  }

  @override
  Future<ExerciseRecord> save(ExerciseRecord record) async {
    final saved = record.id == null ? record.copyWith(id: 'e${++_seq}') : record;
    _records[saved.id!] = saved;
    return saved;
  }

  @override
  Future<void> delete(String id) async {
    _records.remove(id);
  }
}
