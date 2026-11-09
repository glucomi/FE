import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/features/exercise/exercise_models.dart';

/// 서버 운동 API 저장소 (/api/exercises, /api/exercise-records)
///
/// 정책(MO-EXERCISE-010)은 한 기록에 운동을 여러 개 담지만 서버 기록은 운동 1개 단위라서,
/// 운동마다 기록을 하나씩 만들고 같은 일시·메모로 묶어 저장함.
/// 묶인 기록의 id 는 서버 기록 id 를 쉼표로 이은 값 (예: "12,13")
class ApiExerciseRepository implements ExerciseRepository {
  ApiExerciseRepository([ApiClient? client])
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const _records = '/api/exercise-records';

  /// 체중 기록이 없으면 서버가 칼로리를 null 로 줌 → 0 kcal 로 표시
  Exercise _exercise(Map<String, dynamic> json) => Exercise(
    id: '${json['exerciseId']}',
    name: json['name'] as String? ?? '',
    kcalPerBase: asDouble(json['kcalPer30Min'])?.round() ?? 0,
  );

  Future<List<Exercise>> _list(Map<String, Object?> query) async {
    final list =
        await _client.get('/api/exercises', query: query) as List<dynamic>;
    return [for (final item in list) _exercise(item as Map<String, dynamic>)];
  }

  @override
  Future<List<Exercise>> catalog() => _list(const {});

  @override
  Future<List<Exercise>> search(String query) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return const [];
    return _list({'keyword': keyword});
  }

  @override
  Future<List<Exercise>> popular() => _list({'popular': true});

  @override
  Future<List<Exercise>> recent() async {
    final list = await _client.get('/api/exercises/recent') as List<dynamic>;
    return [for (final item in list) _exercise(item as Map<String, dynamic>)];
  }

  /// 서버 기록 한 건 → 운동 1개짜리 기록
  ExerciseRecord _record(Map<String, dynamic> json) {
    final minutes = asInt(json['durationMin']) ?? 0;
    final kcal = asDouble(json['kcal']) ?? 0;
    return ExerciseRecord(
      id: '${json['exerciseRecordId']}',
      time: parseApiDateTime(json['performedAt'] as String),
      memo: json['memo'] as String? ?? '',
      entries: [
        ExerciseEntry(
          exercise: Exercise(
            id: '${json['exerciseId']}',
            name: json['name'] as String? ?? '',
            // 저장된 소모 칼로리를 30분 기준값으로 되돌려 화면 재계산에 사용
            kcalPerBase: minutes == 0
                ? 0
                : (kcal * ExercisePolicy.baseMinutes / minutes).round(),
          ),
          minutes: minutes,
        ),
      ],
    );
  }

  Future<List<ExerciseRecord>> byDate(DateTime day) async {
    final list = await _client.get(
      _records,
      query: {'date': formatApiDate(day)},
    ) as List<dynamic>;
    return [for (final item in list) _record(item as Map<String, dynamic>)];
  }

  Map<String, Object?> _body(ExerciseRecord record, ExerciseEntry entry) => {
    'exerciseId': int.tryParse(entry.exercise.id) ?? entry.exercise.id,
    'performedAt': formatApiDateTime(record.time),
    'durationMin': entry.minutes,
    'memo': record.memo.trim().isEmpty ? null : record.memo.trim(),
  };

  @override
  Future<ExerciseRecord> save(ExerciseRecord record) async {
    final existing = record.id == null
        ? const <String>[]
        : record.id!.split(',').where((id) => id.isNotEmpty).toList();
    final ids = <String>[];
    for (var i = 0; i < record.entries.length; i++) {
      final entry = record.entries[i];
      final json = i < existing.length
          ? await _client.put(
              '$_records/${existing[i]}',
              body: _body(record, entry),
            )
          : await _client.post(_records, body: _body(record, entry));
      ids.add('${(json as Map<String, dynamic>)['exerciseRecordId']}');
    }
    // 수정 중 빠진 운동은 서버 기록도 삭제
    for (final id in existing.skip(record.entries.length)) {
      await _client.delete('$_records/$id');
    }
    return record.copyWith(id: ids.join(','));
  }

  @override
  Future<void> delete(String id) async {
    for (final one in id.split(',').where((v) => v.isNotEmpty)) {
      await _client.delete('$_records/$one');
    }
  }
}
