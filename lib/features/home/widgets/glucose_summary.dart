import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/home_models.dart';

/// 센서 상태 + 오늘 혈당 범위 + 목표 범위
class GlucoseSummary extends StatelessWidget {
  const GlucoseSummary({
    super.key,
    required this.data,
    this.onRefresh,
    this.onConnect,
  });

  final HomeData data;
  final VoidCallback? onRefresh;
  final VoidCallback? onConnect;

  @override
  Widget build(BuildContext context) {
    final connected = data.sensorConnected;
    final bigStyle = AppTypography.displayMd.copyWith(
      color: AppColors.foregroundPrimary,
    );
    final min = data.minGlucose?.round();
    final max = data.maxGlucose?.round();
    final target = data.targetMin != null && data.targetMax != null
        ? '${data.targetMin}-${data.targetMax}mg/dl'
        : '--mg/dl';

    return SizedBox(
      width: double.infinity,
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SensorChip(
                    connected: connected,
                    day: data.sensorDay,
                  ),
                  const SizedBox(height: AppSpacing.spacing1),
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.spacing1),
                    // 글자가 커지거나 화면이 좁으면 줄여서 한 줄 유지
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(min?.toString() ?? '-', style: bigStyle),
                        const SizedBox(width: 2),
                        Text('-', style: bigStyle),
                        const SizedBox(width: 2),
                        if (max != null) ...[
                          Text('$max', style: bigStyle),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          'mg/dl',
                          style: AppTypography.bodyMdR.copyWith(
                            color: AppColors.foregroundPrimary,
                          ),
                        ),
                      ],
                      ),
                    ),
                  ),
                ],
                ),
              ),
              const SizedBox(width: AppSpacing.spacing2),
              connected
                  ? _SmallButton(
                      label: '새로고침',
                      labelColor: AppColors.foregroundQuaternary,
                      trailing: SvgPicture.asset(
                        'assets/home/refresh.svg',
                        width: 12,
                        height: 12,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing2,
                      ),
                      onTap: onRefresh,
                    )
                  : _SmallButton(
                      label: '연결하기',
                      labelColor: AppColors.accentsBrand,
                      trailing: SvgPicture.asset(
                        'assets/home/chevron_right_16.svg',
                        width: 16,
                        height: 16,
                        colorFilter: const ColorFilter.mode(
                          AppColors.accentsBrand,
                          BlendMode.srcIn,
                        ),
                      ),
                      padding: const EdgeInsets.only(
                        left: AppSpacing.spacing2,
                        right: AppSpacing.spacing05,
                      ),
                      onTap: onConnect,
                    ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '목표 범위',
                    style: AppTypography.labelNav.copyWith(
                      color: AppColors.foregroundQuaternary,
                    ),
                  ),
                  Text(
                    target,
                    style: AppTypography.btnSm.copyWith(
                      color: AppColors.foregroundTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorChip extends StatelessWidget {
  const _SensorChip({required this.connected, this.day});

  final bool connected;
  final int? day;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.btnSm.copyWith(color: AppColors.accentsBrand);
    return Container(
      height: 29,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tintBrand,
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('케어센스', style: style),
          const SizedBox(width: AppSpacing.spacing1),
          Text(
            connected ? '${day ?? 1}일차' : '연결 필요',
            style: style.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({
    required this.label,
    required this.labelColor,
    required this.trailing,
    required this.padding,
    this.onTap,
  });

  final String label;
  final Color labelColor;
  final Widget trailing;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 28,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.foregroundOnAccent,
          borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          boxShadow: AppShadows.defaultShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTypography.btnSm.copyWith(color: labelColor)),
            const SizedBox(width: AppSpacing.spacing1),
            trailing,
          ],
        ),
      ),
    );
  }
}
