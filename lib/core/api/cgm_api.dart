import 'package:glucomi/core/api/api_client.dart';

class CgmApi {
  CgmApi([ApiClient? client]) : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// 아이센스 로그인 URL (10분 안에 로그인을 끝내야 함)
  Future<String> authorizeUrl() async {
    final json =
        await _client.get('/api/cgm/oauth/authorize-url')
            as Map<String, dynamic>;
    return json['authorizeUrl'] as String;
  }

  /// 케어센스 데이터를 서버 DB 로 가져옴. 새로 저장된 개수를 돌려줌
  Future<int> sync({required DateTime start, required DateTime end}) async {
    final json =
        await _client.post(
              '/api/cgm/sync',
              query: {
                'start': formatApiDateTime(start),
                'end': formatApiDateTime(end),
              },
            )
            as Map<String, dynamic>;
    return asInt(json['insertedCount']) ?? 0;
  }
}
