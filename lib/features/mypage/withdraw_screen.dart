import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/widgets/curation_step_header.dart';
import 'package:glucomi/features/curation/widgets/diabetes_type_option.dart';
import 'package:glucomi/features/mypage/mypage_models.dart';
import 'package:glucomi/features/mypage/widgets/profile_edit_dialogs.dart';
import 'package:glucomi/shared/widgets/app_button.dart';
import 'package:glucomi/shared/widgets/app_checkbox.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// MO-PROFILE-020 탈퇴하기 (step1 사유 선택 → step2 확인 → step3 최종 팝업)
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key, required this.repository, this.onWithdrawn});

  final MyPageRepository repository;

  /// 탈퇴 후 (첫 화면으로 보내기)
  final VoidCallback? onWithdrawn;

  static const List<String> reasons = [
    '자주 사용하지 않게 됐어요',
    '원하는 기능이 없어요',
    '혈당 기기 연동/측정이 불편해요',
    '사용법이 어렵고 복잡해요',
    '개인정보/데이터 보안이 걱정돼요',
  ];

  static const List<({String title, String description})> notices = [
    (title: '처음부터 다시 가입해야 해요', description: '탈퇴하시면 회원가입부터 다시 해야 해요'),
    (title: '혈당/식사 기록이 모두 삭제돼요', description: '그동안 쌓은 기록과 리포트를 다시 볼 수 없어요'),
    (
      title: '지금까지 키운 농장이 사라져요',
      description: 'CGM 데이터로 건강을 지키며 키운 농장이 사라져요',
    ),
  ];

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  int _step = 1;
  String? _reason;
  late final List<bool> _checked = List.filled(
    WithdrawScreen.notices.length,
    false,
  );
  bool _submitting = false;

  bool get _allChecked => _checked.every((c) => c);

  void _back() {
    if (_step == 2) {
      setState(() => _step = 1);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _confirm() async {
    if (!_allChecked || _submitting) return;
    final withdraw = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0xB3000000), // DIM: black 70%
      builder: (_) => const _WithdrawConfirmDialog(),
    );
    if (withdraw != true || !mounted) return;

    setState(() => _submitting = true);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.repository.withdraw(_reason ?? '');
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      showAppToastOn(
        messenger,
        '탈퇴하지 못했어요. 다시 시도해주세요.',
        type: AppToastType.error,
      );
      return;
    }
    if (!mounted) return;
    final onWithdrawn = widget.onWithdrawn;
    if (onWithdrawn != null) {
      onWithdrawn();
    } else {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: AppColors.neutralsBackground,
        body: SafeArea(
          child: Column(
            children: [
              AppHeaderBar(title: '탈퇴하기', onBack: _back),
              Expanded(
                child: SingleChildScrollView(
                  child: _step == 1 ? _buildReasonStep() : _buildNoticeStep(),
                ),
              ),
              if (_step == 1)
                BottomActionBar(
                  label: '다음',
                  onPressed: _reason == null
                      ? null
                      : () => setState(() => _step = 2),
                )
              else
                BottomActionBar(
                  label: '탈퇴하기',
                  onPressed: _allChecked && !_submitting ? _confirm : null,
                  secondaryLabel: '더 써볼래요',
                  onSecondaryPressed: () => Navigator.of(context).maybePop(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReasonStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CurationStepHeader(
          step: 1,
          totalSteps: 2,
          title: '탈퇴 사유를 선택해 주세요',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing5,
            vertical: AppSpacing.spacing4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, reason) in WithdrawScreen.reasons.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.spacing3),
                DiabetesTypeOption(
                  key: ValueKey('withdraw-reason-$i'),
                  label: reason,
                  selected: reason == _reason,
                  onTap: () => setState(() => _reason = reason),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CurationStepHeader(
          step: 2,
          totalSteps: 2,
          title: '정말 탈퇴하시겠습니까?',
          description: '아래 항목을 읽고 체크해주세요',
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing5,
            vertical: AppSpacing.spacing4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, notice) in WithdrawScreen.notices.indexed) ...[
                if (i > 0) const SizedBox(height: AppSpacing.spacing3),
                _NoticeCard(
                  key: ValueKey('withdraw-notice-$i'),
                  title: notice.title,
                  description: notice.description,
                  checked: _checked[i],
                  onChanged: (v) => setState(() => _checked[i] = v),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    super.key,
    required this.title,
    required this.description,
    required this.checked,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!checked),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing4,
          AppSpacing.spacing4,
          AppSpacing.spacing4,
          AppSpacing.spacing3,
        ),
        decoration: BoxDecoration(
          color: AppColors.neutralsSubtle,
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
          border: Border.all(color: AppColors.borderStrong),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyLgM.copyWith(
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing1),
                  Text(
                    description,
                    style: AppTypography.bodySmR.copyWith(
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.spacing1),
            AppCheckbox(
              value: checked,
              onChanged: onChanged,
              size: AppCheckboxSize.lg,
            ),
          ],
        ),
      ),
    );
  }
}

/// step3 최종 확인 팝업 — '탈퇴하기'면 true
class _WithdrawConfirmDialog extends StatelessWidget {
  const _WithdrawConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        decoration: BoxDecoration(
          color: AppColors.neutralsBackground,
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.radiusXl),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
              child: Column(
                children: [
                  Text(
                    '탈퇴하기',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMdM.copyWith(
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing05),
                  Text(
                    '정말 탈퇴하시겠습니까?',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmR.copyWith(
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.spacing3),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    key: const ValueKey('withdraw-confirm'),
                    label: '탈퇴하기',
                    height: AppSpacing.controlHeightMd,
                    horizontalPadding: AppSpacing.spacing4,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing3),
                Expanded(
                  child: AppSmallButton(
                    key: const ValueKey('withdraw-stay'),
                    label: '더 써볼래요',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
