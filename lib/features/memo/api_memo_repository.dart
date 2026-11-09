import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/features/memo/memo_models.dart';

/// 서버 메모 API 저장소 (/api/memo-records)
///
/// 서버는 아직 사진 첨부를 받지 않고 내용(content)이 필수라서
/// 사진만 있는 메모는 저장하지 않고 안내함 (BE 확장 필요)
class ApiMemoRepository implements MemoRepository {
  ApiMemoRepository([ApiClient? client])
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  static const _base = '/api/memo-records';

  MemoRecord _fromJson(Map<String, dynamic> json) => MemoRecord(
    id: '${json['memoRecordId']}',
    time: parseApiDateTime(json['recordedAt'] as String),
    text: json['content'] as String? ?? '',
  );

  Future<List<MemoRecord>> byDate(DateTime day) async {
    final list = await _client.get(
      _base,
      query: {'date': formatApiDate(day)},
    ) as List<dynamic>;
    return [for (final item in list) _fromJson(item as Map<String, dynamic>)];
  }

  @override
  Future<MemoRecord> save(MemoRecord record) async {
    final content = record.text.trim();
    if (content.isEmpty) {
      throw const ApiException(
        message: '사진만 있는 메모는 아직 저장할 수 없어요. 내용을 함께 입력해주세요.',
      );
    }
    final body = {
      'recordedAt': formatApiDateTime(record.time),
      'content': content,
    };
    final json = record.id == null
        ? await _client.post(_base, body: body)
        : await _client.put('$_base/${record.id}', body: body);
    final saved = _fromJson(json as Map<String, dynamic>);
    // 사진은 서버에 저장되지 않지만 이번 화면 결과에는 남겨 둠
    return MemoRecord(
      id: saved.id,
      time: saved.time,
      text: saved.text,
      photos: record.photos,
    );
  }

  @override
  Future<void> delete(String id) async {
    await _client.delete('$_base/$id');
  }
}
