import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/mypage/mypage_models.dart';
import 'package:glucomi/features/mypage/widgets/profile_edit_dialogs.dart';
import 'package:glucomi/features/mypage/withdraw_screen.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';

/// MO-PROFILE-010 마이페이지 - 프로필 수정 (내 프로필)
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.repository, this.onLoggedOut});

  final MyPageRepository repository;

  /// 로그아웃·탈퇴 후 (첫 화면으로 보내기)
  final VoidCallback? onLoggedOut;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile get _profile =>
      widget.repository.data?.profile ?? MyPageRepository.sample.profile;

  Future<void> _save(UserProfile profile) async {
    final messenger = ScaffoldMessenger.of(context);
    await widget.repository.updateProfile(profile);
    if (!mounted) return;
    setState(() {});
    showAppToastOn(
      messenger,
      '변경 완료되었습니다',
      type: AppToastType.success,
    );
  }

  Future<void> _editName() async {
    final name = await showNameEditDialog(context, _profile.name);
    if (name != null) await _save(_profile.copyWith(name: name));
  }

  Future<void> _editBirth() async {
    final date = await showBirthEditDialog(context, _profile.birthDate);
    if (date != null) await _save(_profile.copyWith(birthDate: date));
  }

  Future<void> _editGender() async {
    final gender = await showGenderEditDialog(context, _profile.gender);
    if (gender != null) await _save(_profile.copyWith(gender: gender));
  }

  Future<void> _editHeight() async {
    final height = await showHeightEditDialog(context, _profile.heightCm);
    if (height != null) await _save(_profile.copyWith(heightCm: height));
  }

  Future<void> _editDiabetes() async {
    final type = await showDiabetesEditDialog(context, _profile.diabetesType);
    if (type != null) await _save(_profile.copyWith(diabetesType: type));
  }

  Future<void> _logout() async {
    final navigator = Navigator.of(context);
    await widget.repository.logout();
    if (!mounted) return;
    final onLoggedOut = widget.onLoggedOut;
    if (onLoggedOut != null) {
      onLoggedOut();
    } else {
      navigator.popUntil((route) => route.isFirst);
    }
  }

  void _withdraw() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WithdrawScreen(
          repository: widget.repository,
          onWithdrawn: widget.onLoggedOut,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final birth = profile.birthDate;

    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '내 프로필',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.spacing2),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacing4),
                      child: _Avatar(
                        onEdit: () => showAppToast(context, '프로필 사진 변경 준비 중입니다.'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.spacing2),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacing4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.spacing2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.neutralsSurface,
                          borderRadius: BorderRadius.circular(
                            AppRadius.radiusSm,
                          ),
                          border: Border.all(color: AppColors.borderStrong),
                        ),
                        child: Column(
                          children: [
                            _ProfileRow(
                              keyName: 'name',
                              label: '이름',
                              value: profile.name,
                              onTap: _editName,
                            ),
                            _ProfileRow(
                              keyName: 'birth',
                              label: '생년월일',
                              value: birth == null
                                  ? '-'
                                  : '${birth.year}.'
                                        '${birth.month.toString().padLeft(2, '0')}.'
                                        '${birth.day.toString().padLeft(2, '0')}',
                              onTap: _editBirth,
                            ),
                            _ProfileRow(
                              keyName: 'gender',
                              label: '성별',
                              value: profile.gender?.displayLabel ?? '-',
                              onTap: _editGender,
                            ),
                            _ProfileRow(
                              keyName: 'height',
                              label: '키',
                              value: profile.heightCm == null
                                  ? '-'
                                  : '${profile.heightCm}cm',
                              onTap: _editHeight,
                            ),
                            _ProfileRow(
                              keyName: 'diabetes',
                              label: '당뇨 여부',
                              value: profile.diabetesType?.label ?? '-',
                              onTap: _editDiabetes,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TextButton(
                    key: const ValueKey('profile-logout'),
                    label: '로그아웃',
                    onTap: _logout,
                  ),
                  const SizedBox(width: AppSpacing.spacing3),
                  const SizedBox(
                    width: 1,
                    height: 16,
                    child: ColoredBox(color: AppColors.neutralsSubtle),
                  ),
                  const SizedBox(width: AppSpacing.spacing3),
                  _TextButton(
                    key: const ValueKey('profile-withdraw'),
                    label: '탈퇴 하기',
                    onTap: _withdraw,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.neutralsSurface,
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              'assets/mypage/avatar_user.svg',
              width: 68.4,
              height: 68.4,
              excludeFromSemantics: true,
            ),
          ),
          Positioned(
            left: 70,
            top: 70,
            child: GestureDetector(
              key: const ValueKey('profile-avatar-edit'),
              behavior: HitTestBehavior.opaque,
              onTap: onEdit,
              child: Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.gray10,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gray100),
                ),
                child: SvgPicture.asset(
                  'assets/mypage/pencil_edit_12_light.svg',
                  width: 12,
                  height: 12,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.keyName,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String keyName;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('profile-row-$keyName'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing4,
          vertical: AppSpacing.spacing3,
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.bodyMdM.copyWith(
                color: AppColors.foregroundSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.spacing4),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLgM.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.spacing2),
            SvgPicture.asset(
              'assets/mypage/pencil_edit_12.svg',
              width: 12,
              height: 12,
              excludeFromSemantics: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TextButton extends StatelessWidget {
  const _TextButton({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: AppSpacing.controlHeightSm,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing3),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.btnMd.copyWith(
            color: AppColors.foregroundQuaternary,
          ),
        ),
      ),
    );
  }
}
