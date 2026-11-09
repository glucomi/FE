import 'package:flutter/material.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/features/login/kakao_oauth_flow.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';

/// MO-LOGIN-010 · Figma node 2878:19195.
/// A genuine OAuth flow, not a simulated successful sign-in.
class KakaoLoginScreen extends StatefulWidget {
  const KakaoLoginScreen({super.key, this.flow});
  final KakaoOAuthFlow? flow;

  @override
  State<KakaoLoginScreen> createState() => _KakaoLoginScreenState();
}

class _KakaoLoginScreenState extends State<KakaoLoginScreen> {
  late final KakaoOAuthFlow _flow = widget.flow ?? KakaoOAuthFlow();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (_flow.hasWebCallback) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _completeCallback());
    }
  }

  Future<void> _completeCallback() async => _run(_flow.completeWebLogin);

  Future<void> _run(Future<void> Function() work) async {
    if (_loading || !mounted) return;
    setState(() => _loading = true);
    try {
      await work();
    } on KakaoLoginCancelled {
      // Policy: a cancelled login stays here without any toast.
    } catch (e) {
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : e is StateError
            ? e.message
            : '카카오 로그인을 완료하지 못했어요.';
        showAppToast(context, message.toString(), type: AppToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFE),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Positioned(
                  top: constraints.maxHeight * 0.16,
                  left: 0,
                  right: 0,
                  child: const Column(
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
                Positioned(
                  left: 15,
                  right: 15,
                  bottom: 62,
                  height: 54,
                  child: Semantics(
                    button: true,
                    label: '카카오로 시작하기',
                    child: ElevatedButton(
                      key: const ValueKey('kakao-login-button'),
                      onPressed: _loading ? null : () => _run(_flow.login),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFFEE500),
                        disabledBackgroundColor: const Color(0xFFFEE500),
                        foregroundColor: const Color(0xD9000000),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xD9000000),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/login/kakao_logo.png',
                                  height: 18,
                                  width: 18,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  '카카오로 시작하기',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
