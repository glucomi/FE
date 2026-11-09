import 'package:web/web.dart' as web;

/// 카카오 인증 후 돌아온 주소의 ?code=…&state=… 를 지움
///
/// 남겨 두면 새로고침·로그아웃 뒤에 이미 쓴 인가 코드로 다시 로그인을 시도함
void clearOAuthCallbackFromUrl() {
  final location = web.window.location;
  web.window.history.replaceState(
    null,
    '',
    '${location.pathname}${location.hash}',
  );
}
