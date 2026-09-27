import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/home_models.dart';

const _statText = Color(0xFF515766);
const _titleText = Color(0xFF354051);

/// 혈당 점수 + 최고/평균 혈당, 스파이크, 탄수화물
class GlucoseStats extends StatelessWidget {
  const GlucoseStats({super.key, required this.data});

  final HomeData data;

  String _format(num? value) => value == null ? '--' : '${value.round()}';

  @override
  Widget build(BuildContext context) {
    final titleStyle = AppTypography.headingH3.copyWith(color: _titleText);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
            vertical: AppSpacing.spacing5,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            children: [
              Text('혈당 점수', style: titleStyle),
              const Spacer(),
              Text(data.score?.toString() ?? '-', style: titleStyle),
              const SizedBox(width: AppSpacing.spacing1),
              Text('점', style: titleStyle),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.spacing3),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: '최고 혈당',
                value: _format(data.maxGlucose),
                unit: 'mg/dl',
              ),
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: _StatTile(
                label: '평균 혈당',
                value: _format(data.averageGlucose),
                unit: 'mg/dl',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.spacing3),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: '스파이크',
                value: _format(data.spikeCount),
                unit: '회',
              ),
            ),
            const SizedBox(width: AppSpacing.spacing3),
            Expanded(
              child: _StatTile(
                label: '탄수화물',
                value: _format(data.carbsGram),
                unit: 'g',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14A7A7A7),
            offset: Offset(0, 4),
            blurRadius: 18,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelMeta.copyWith(
              color: AppColors.foregroundQuaternary,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppTypography.bodyLgM.copyWith(color: _statText)),
              const SizedBox(width: 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  unit,
                  style: AppTypography.bodyXsR.copyWith(color: _statText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
