import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/signup/term_document_screen.dart';
import 'package:glucomi/features/signup/widgets/signup_all_consent_card.dart';
import 'package:glucomi/features/signup/widgets/signup_consent_row.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

@immutable
class SignupConsent {
  const SignupConsent({
    required this.age,
    required this.terms,
    required this.privacy,
    required this.quality,
    required this.marketing,
  });

  final bool age;
  final bool terms;
  final bool privacy;
  final bool quality;
  final bool marketing;
}

enum SignupTerm { terms, privacy, quality }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, this.onSubmit, this.onOpenTerm, this.onBack});

  final Future<void> Function(SignupConsent consent)? onSubmit;
  final void Function(SignupTerm term)? onOpenTerm;
  final VoidCallback? onBack;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _checked = List<bool>.filled(5, false);
  bool _submitting = false;

  bool get _all => _checked.every((value) => value);
  bool get _ready => _checked.take(3).every((value) => value);

  static const _labels = [
    '[필수] 만 14세 이상입니다',
    '[필수] 이용약관',
    '[필수] 개인정보 수집 및 이용',
    '[선택] 서비스 품질 향상',
    '[선택] 이벤트 및 혜택 알림 수신',
  ];

  void _message(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _setAll(bool value) {
    if (_submitting) return;

    setState(() {
      _checked.fillRange(0, _checked.length, value);
    });
  }

  void _setChecked(int index, bool value) {
    if (_submitting) return;

    setState(() {
      _checked[index] = value;
    });
  }

  Future<void> _submit() async {
    if (!_ready || _submitting) return;

    if (widget.onSubmit == null) {
      _message('회원가입 서비스 연결 준비 중입니다.');
      return;
    }

    setState(() => _submitting = true);

    try {
      await widget.onSubmit!(
        SignupConsent(
          age: _checked[0],
          terms: _checked[1],
          privacy: _checked[2],
          quality: _checked[3],
          marketing: _checked[4],
        ),
      );
    } catch (_) {
      if (mounted) {
        _message('가입을 완료하지 못했어요. 다시 시도해 주세요.');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _openTerm(int index) {
    final term = SignupTerm.values[index - 1];

    if (widget.onOpenTerm != null) {
      widget.onOpenTerm!(term);
      return;
    }

    final detail = switch (term) {
      SignupTerm.terms => (title: '이용약관', assetPath: 'assets/terms/terms.pdf'),
      SignupTerm.privacy => (
        title: '개인정보 수집 및 이용',
        assetPath: 'assets/terms/privacy.pdf',
      ),
      SignupTerm.quality => (
        title: '서비스 품질 향상',
        assetPath: 'assets/terms/quality.pdf',
      ),
    };

    Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => TermDocumentScreen(
          title: detail.title,
          pdfAssetPath: detail.assetPath,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: DefaultTextStyle(
          style: AppTypography.bodyMdR.copyWith(
            color: AppColors.foregroundPrimary,
          ),
          child: Column(
            children: [
              AppHeaderBar(
                onBack: widget.onBack ?? () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing5,
                          vertical: AppSpacing.spacing4,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '반가워요!',
                              style: AppTypography.displaySm.copyWith(
                                color: AppColors.foregroundPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.spacing2),
                            Text(
                              '따당을 사용하시려면 동의가 필요해요',
                              style: AppTypography.bodyMdR.copyWith(
                                color: AppColors.foregroundQuaternary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.spacing5,
                          vertical: AppSpacing.spacing4,
                        ),
                        child: Column(
                          children: [
                            SignupAllConsentCard(
                              checked: _all,
                              enabled: !_submitting,
                              onChanged: _setAll,
                            ),
                            for (var i = 0; i < _checked.length; i++) ...[
                              const SizedBox(height: AppSpacing.spacing3),
                              SignupConsentRow(
                                index: i,
                                label: _labels[i],
                                checked: _checked[i],
                                enabled: !_submitting,
                                onChanged: (value) => _setChecked(i, value),
                                onOpenDetail: i >= 1 && i <= 3
                                    ? () => _openTerm(i)
                                    : null,
                                reserveTrailingSpace: i == 0,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              BottomActionBar(
                key: const ValueKey('signup-next'),
                label: '다음',
                onPressed: _ready && !_submitting ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
