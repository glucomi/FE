import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/mypage/mypage_models.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_switch.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';

/// MO-ALARM-010 알림 설정
class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key, required this.repository, this.now});

  final MyPageRepository repository;

  /// 토스트에 찍을 현재 시각 (테스트용)
  final DateTime Function()? now;

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  NotificationSettings get _settings =>
      widget.repository.data?.notifications ?? const NotificationSettings();

  /// 2026.08.28 11:00
  String _timestamp() {
    final t = (widget.now ?? DateTime.now)();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}.${two(t.month)}.${two(t.day)} ${two(t.hour)}:${two(t.minute)}';
  }

  Future<void> _change({bool? push, bool? marketing}) async {
    final messenger = ScaffoldMessenger.of(context);
    await widget.repository.updateNotifications(
      _settings.copyWith(push: push, marketing: marketing),
    );
    if (!mounted) return;
    setState(() {});

    final name = push != null ? 'PUSH 알림' : '마케팅 수신';
    final agreed = (push ?? marketing) == true;
    // 동의는 Figma 문구, 철회는 디자인에 없어 같은 형식으로 둠
    showAppToastOn(
      messenger,
      agreed
          ? '$name에 동의하셨습니다 (${_timestamp()})'
          : '$name 동의를 철회하셨습니다 (${_timestamp()})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;

    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '알림 설정',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing4,
                vertical: AppSpacing.spacing4,
              ),
              child: Column(
                children: [
                  _AlarmRow(
                    key: const ValueKey('alarm-push'),
                    title: 'PUSH 알림',
                    description: '혈당 관련 알림 받기',
                    value: settings.push,
                    onChanged: (v) => _change(push: v),
                  ),
                  const SizedBox(height: AppSpacing.spacing6),
                  _AlarmRow(
                    key: const ValueKey('alarm-marketing'),
                    title: '마케팅 수신 동의',
                    description: '혜택, 이벤트, 프로모션 정보',
                    value: settings.marketing,
                    onChanged: (v) => _change(marketing: v),
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

class _AlarmRow extends StatelessWidget {
  const _AlarmRow({
    super.key,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.spacing2,
          vertical: AppSpacing.spacing3,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headingH3.copyWith(
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: AppTypography.labelMeta.copyWith(
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                ],
              ),
            ),
            AppSwitch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
