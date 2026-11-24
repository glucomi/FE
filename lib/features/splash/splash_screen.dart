import 'dart:async';

import 'package:flutter/material.dart';

/// MO-SPLASH-010 스플래시
///
/// 정책: 2000ms 노출 후 다음 화면으로 넘어감 (뒤로가기로 돌아올 수 없음)
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    required this.next,
    this.duration = SplashScreen.defaultDuration,
  });

  static const Duration defaultDuration = Duration(milliseconds: 2000);

  /// 스플래시 뒤에 보여줄 화면 (로그인 상태에 따라 로그인/약관/큐레이션/홈 분기)
  final Widget next;

  final Duration duration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, _goNext);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => widget.next,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 디자인 미확정 — 로그인 화면(MO-LOGIN-010)과 같은 로고 문구를 가운데에 둠
    return const Scaffold(
      key: ValueKey('splash'),
      backgroundColor: Color(0xFFFEFEFE),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '따끔한 당뇨 코치',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 28,
                fontWeight: FontWeight.w500,
                height: 44 / 28,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 7),
            Text(
              '따당',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 32,
                fontWeight: FontWeight.w700,
                height: 44 / 32,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
