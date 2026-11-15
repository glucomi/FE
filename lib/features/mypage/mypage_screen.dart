import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/widgets/home_dock_bar.dart';
import 'package:glucomi/features/mypage/alarm_screen.dart';
import 'package:glucomi/features/mypage/goal_screen.dart';
import 'package:glucomi/features/mypage/mypage_models.dart';
import 'package:glucomi/features/mypage/profile_screen.dart';
import 'package:glucomi/features/signup/term_document_screen.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';

/// MO-MYPAGE-010 마이페이지-홈
class MyPageScreen extends StatefulWidget {
  const MyPageScreen({
    super.key,
    required this.repository,
    this.sensor,
    this.onConnectSensor,
    this.onSelectTab,
    this.onLoggedOut,
  });

  final MyPageRepository repository;

  /// 홈에서 받은 센서 상태 (없으면 저장소 값)
  final SensorStatus? sensor;

  /// 센서 카드 / 센서 연결 탭 — 홈과 같은 아이센스 연결 흐름
  final Future<void> Function()? onConnectSensor;

  /// 하단 탭바에서 마이페이지 말고 다른 탭을 눌렀을 때
  final ValueChanged<HomeTab>? onSelectTab;

  /// 로그아웃·탈퇴 후 (첫 화면으로 보내기)
  final VoidCallback? onLoggedOut;

  @override
  State<MyPageScreen> createState() => _MyPageScreenState();
}

class _MyPageScreenState extends State<MyPageScreen> {
  late Future<MyPageData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.repository.load(sensor: widget.sensor);
    widget.repository.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.repository.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final data = widget.repository.data;
    if (data != null && mounted) setState(() => _future = Future.value(data));
  }

  void _retry() {
    setState(() => _future = widget.repository.load(sensor: widget.sensor));
  }

  void _notReady(String feature) {
    showAppToast(context, '$feature 준비 중입니다.');
  }

  Future<void> _push(Widget screen) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  void _openProfile() => _push(
    ProfileScreen(
      repository: widget.repository,
      onLoggedOut: widget.onLoggedOut,
    ),
  );

  void _openGoal() => _push(GoalScreen(repository: widget.repository));

  void _openAlarm() => _push(AlarmScreen(repository: widget.repository));

  void _openTerm(String title, String asset) =>
      _push(TermDocumentScreen(title: title, pdfAssetPath: asset));

  Future<void> _connectSensor() async {
    final connect = widget.onConnectSensor;
    if (connect == null) {
      _notReady('센서 연결');
      return;
    }
    await connect();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      bottomNavigationBar: HomeDockBar(
        current: HomeTab.myPage,
        onSelect: (tab) {
          if (tab != HomeTab.myPage) widget.onSelectTab?.call(tab);
        },
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.neutralsBackground,
            padding: EdgeInsets.only(top: topInset),
            child: Container(
              height: AppSpacing.controlHeightXl,
              padding: const EdgeInsets.only(left: 22),
              alignment: Alignment.centerLeft,
              child: Text(
                '마이페이지',
                style: AppTypography.headingH2.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<MyPageData>(
              future: _future,
              builder: (context, snapshot) {
                final data = snapshot.data;
                if (data == null) {
                  if (snapshot.hasError) {
                    return _ErrorView(onRetry: _retry);
                  }
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildBody(data);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(MyPageData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: AppSpacing.spacing4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            gap: AppSpacing.spacing4,
            children: [
              _ProfileHeader(name: data.profile.name, onTap: _openProfile),
              _QuickMenu(
                onMembership: () => _notReady('멤버십 관리'),
                onSensor: _connectSensor,
                onNotice: () => _notReady('공지사항'),
              ),
              _SensorCard(status: data.sensor, onTap: _connectSensor),
              _TargetCard(
                min: data.targetMin,
                max: data.targetMax,
                onTap: _openGoal,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing2),
          _MenuSection(
            title: '설정 관리',
            items: [_MenuItem('알림 설정', _openAlarm)],
          ),
          const SizedBox(height: AppSpacing.spacing2),
          _MenuSection(
            title: '이용 안내',
            items: [
              _MenuItem('공지사항', () => _notReady('공지사항')),
              _MenuItem('문의', () => _notReady('문의')),
              _MenuItem(
                '이용약관',
                () => _openTerm('이용약관', 'assets/terms/terms.pdf'),
              ),
              _MenuItem(
                '개인정보처리방침',
                () => _openTerm('개인정보처리방침', 'assets/terms/privacy.pdf'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 흰 배경 + 위아래 border 섹션
class _Section extends StatelessWidget {
  const _Section({required this.children, this.gap = 0});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: const BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.borderDefault),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final child in children) ...[
            if (child != children.first) SizedBox(height: gap),
            child,
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('mypage-profile'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/mypage/avatar_50.svg',
            width: 50,
            height: 50,
            excludeFromSemantics: true,
          ),
          const SizedBox(width: AppSpacing.spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name님',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLgM.copyWith(
                    color: AppColors.foregroundPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '프로필 수정',
                      style: AppTypography.bodySmM.copyWith(
                        color: AppColors.foregroundTertiary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacing1),
                    SvgPicture.asset(
                      'assets/mypage/pencil_10.svg',
                      width: 10,
                      height: 10,
                      excludeFromSemantics: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 멤버십 관리 | 센서 연결 | 공지사항
class _QuickMenu extends StatelessWidget {
  const _QuickMenu({
    required this.onMembership,
    required this.onSensor,
    required this.onNotice,
  });

  final VoidCallback onMembership;
  final VoidCallback onSensor;
  final VoidCallback onNotice;

  @override
  Widget build(BuildContext context) {
    Widget item(String key, String label, String image, VoidCallback onTap) {
      return Expanded(
        child: GestureDetector(
          key: ValueKey(key),
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing3),
            child: Column(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: Image.asset(image, width: 44, height: 48),
                  ),
                ),
                const SizedBox(height: AppSpacing.spacing15),
                Text(
                  label,
                  style: AppTypography.bodyXsM.copyWith(
                    color: AppColors.foregroundSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    const separator = SizedBox(
      width: 1,
      height: 32,
      child: ColoredBox(color: AppColors.neutralsSubtle),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing1),
      child: Row(
        children: [
          item(
            'mypage-membership',
            '멤버십 관리',
            'assets/mypage/membership.webp',
            onMembership,
          ),
          separator,
          item(
            'mypage-sensor',
            '센서 연결',
            'assets/mypage/sensor.webp',
            onSensor,
          ),
          separator,
          item(
            'mypage-notice',
            '공지사항',
            'assets/mypage/notice.webp',
            onNotice,
          ),
        ],
      ),
    );
  }
}

/// 센서 상태 카드 (미연결 / 정상 연결 / 연결 끊김)
class _SensorCard extends StatelessWidget {
  const _SensorCard({required this.status, required this.onTap});

  final SensorStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (
      Color background,
      Color border,
      Color accent,
      Color chipBackground,
      String title,
      String message,
      String chipValue,
    ) = switch (status.state) {
      SensorState.none => (
        AppColors.neutralsSurface,
        AppColors.borderDefault,
        AppColors.foregroundTertiary,
        AppColors.neutralsMuted,
        '센서 미연결',
        '센서가 아직 연결되지 않았어요',
        '필요',
      ),
      SensorState.connected => (
        AppColors.green50.withValues(alpha: 0.5),
        AppColors.green50,
        AppColors.accentsBrand,
        AppColors.green100,
        status.deviceName ?? '케어센스에어',
        '정상적으로 연결되어 있어요',
        _dayLabel(status.day),
      ),
      SensorState.disconnected => (
        AppColors.statusErrorSubtle.withValues(alpha: 0.5),
        AppColors.statusErrorSubtle,
        AppColors.accentsDanger,
        AppColors.interactiveDangerDisabled,
        status.deviceName ?? '케어센스에어',
        '센서 연결이 끊겼어요',
        _dayLabel(status.day),
      ),
    };

    return GestureDetector(
      key: const ValueKey('mypage-sensor-card'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing3,
          AppSpacing.spacing2,
          AppSpacing.spacing2,
          AppSpacing.spacing2,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            const _SensorImage(),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.spacing2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMdM.copyWith(
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        if (status.state == SensorState.none)
                          Container(width: 4, height: 1, color: accent)
                        else
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        const SizedBox(width: AppSpacing.spacing1),
                        Flexible(
                          child: Text(
                            message,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyXsR.copyWith(
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 24,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing2,
              ),
              decoration: BoxDecoration(
                color: chipBackground,
                borderRadius: BorderRadius.circular(AppRadius.radiusFull),
              ),
              alignment: Alignment.center,
              child: Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(text: '연결 '),
                    TextSpan(
                      text: chipValue,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                style: AppTypography.btnSm.copyWith(color: accent),
              ),
            ),
            const SizedBox(width: AppSpacing.spacing1),
            SvgPicture.asset(
              'assets/home/chevron_right_16.svg',
              width: 16,
              height: 16,
              colorFilter: ColorFilter.mode(
                status.state == SensorState.connected
                    ? AppColors.green300
                    : accent,
                BlendMode.srcIn,
              ),
              excludeFromSemantics: true,
            ),
          ],
        ),
      ),
    );
  }

  static String _dayLabel(int? day) => day == null ? '중' : '$day일차';
}

/// 센서 이미지 + 바닥 그림자
class _SensorImage extends StatelessWidget {
  const _SensorImage();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 51,
      height: 37,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 5.3 - 8,
            top: 30.8 - 8,
            child: Transform.rotate(
              angle: 4.48 * 3.1415926535 / 180,
              child: SvgPicture.asset(
                'assets/mypage/sensor_shadow.svg',
                width: 39.9,
                height: 19.7,
                excludeFromSemantics: true,
              ),
            ),
          ),
          Image.asset('assets/mypage/device.webp', width: 51, height: 37),
        ],
      ),
    );
  }
}

/// 내 목표 혈당 범위 (브랜드 컬러 카드)
class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.min, required this.max, required this.onTap});

  final int? min;
  final int? max;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final range = min != null && max != null ? '$min~$max' : '-';
    const onAccent = AppColors.neutralsBackground;

    return GestureDetector(
      key: const ValueKey('mypage-target'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.spacing3,
          AppSpacing.spacing4,
          AppSpacing.spacing2,
          AppSpacing.spacing4,
        ),
        decoration: BoxDecoration(
          color: AppColors.accentsBrand,
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          border: Border.all(color: AppColors.focusRingBrand),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/mypage/glucose_drop.svg',
              width: 12,
              height: 12,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
            const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: Text(
                '내 목표 혈당 범위',
                style: AppTypography.bodySmR.copyWith(color: onAccent),
              ),
            ),
            Text(
              range,
              style: AppTypography.bodyMdM.copyWith(color: onAccent),
            ),
            const SizedBox(width: AppSpacing.spacing05),
            Opacity(
              opacity: 0.7,
              child: Text(
                'mg/dL',
                style: AppTypography.bodySmR.copyWith(color: onAccent),
              ),
            ),
            const SizedBox(width: AppSpacing.spacing1),
            SvgPicture.asset(
              'assets/home/chevron_right_16.svg',
              width: 16,
              height: 16,
              colorFilter: const ColorFilter.mode(
                AppColors.green300,
                BlendMode.srcIn,
              ),
              excludeFromSemantics: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.label, this.onTap);

  final String label;
  final VoidCallback onTap;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});

  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    return _Section(
      children: [
        Text(
          title,
          style: AppTypography.headingH3.copyWith(color: Colors.black),
        ),
        const SizedBox(height: AppSpacing.spacing1),
        for (final item in items)
          GestureDetector(
            key: ValueKey('mypage-menu-${item.label}'),
            behavior: HitTestBehavior.opaque,
            onTap: item.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTypography.bodyMdR.copyWith(
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SvgPicture.asset(
                    'assets/home/chevron_right_16.svg',
                    width: 16,
                    height: 16,
                    colorFilter: const ColorFilter.mode(
                      AppColors.foregroundQuaternary,
                      BlendMode.srcIn,
                    ),
                    excludeFromSemantics: true,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '내 정보를 불러오지 못했어요.',
            style: AppTypography.bodyMdR.copyWith(
              color: AppColors.foregroundTertiary,
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
