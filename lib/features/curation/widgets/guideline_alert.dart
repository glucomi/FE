import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 목표 혈당 범위 안내 (Figma Alert)
class GuidelineAlert extends StatelessWidget {
  const GuidelineAlert({super.key});

  static const _items = [
    '제1형·2형 당뇨: 70~180 mg/dL (대한당뇨병학회)',
    '임신성 당뇨: 63~140 mg/dL (대한당뇨병학회, 임신 기준)',
    '일반인·전당뇨: 70~140 mg/dL (정상 혈당 참고 범위)',
  ];

  @override
  Widget build(BuildContext context) {
    final bodyStyle = AppTypography.bodySmR.copyWith(
      color: AppColors.foregroundTertiary,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: AppColors.neutralsSubtle,
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        border: Border.all(
          color: AppColors.borderStrong,
          width: AppTokens.borderWidthDefault,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/curation/info.svg',
                width: 20,
                height: 20,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                '당뇨병 진료지침',
                style: AppTypography.bodyMdM.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing1),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 12, child: Text('•', style: bodyStyle)),
                  // Figma 기준 한 줄에 맞추기 위해 좁은 화면에서는 살짝 축소
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(item, style: bodyStyle, maxLines: 1),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text('본 범위는 일반 지침이며 의학적 조언이 아닙니다.', style: bodyStyle),
          ),
        ],
      ),
    );
  }
}
