import 'package:flutter/material.dart';

/// 앱 전체 스크롤바 숨김 (웹 미리보기에서 오른쪽 스크롤바가 보이지 않도록)
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
