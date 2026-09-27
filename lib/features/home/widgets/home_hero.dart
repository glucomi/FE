import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 홈 상단 — 배경 이미지, 홈/Q&A 탭, 알림, 오늘의 제안 문구
class HomeHero extends StatelessWidget {
  const HomeHero({
    super.key,
    required this.message,
    this.showSuggestionChips = false,
    this.hasNotification = true,
    this.onTapNotification,
  });

  final String message;
  final bool showSuggestionChips;
  final bool hasNotification;
  final VoidCallback? onTapNotification;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderTabs(
              hasNotification: hasNotification,
              onTapNotification: onTapNotification,
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing6),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.white.withValues(alpha: 0.5),
                  ],
                ).createShader(bounds),
                child: Text(
                  message,
                  style: AppTypography.displaySm.copyWith(color: Colors.white),
                ),
              ),
            ),
            if (showSuggestionChips) ...[
              const SizedBox(height: 9),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.spacing6),
                child: _SuggestionChips(),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeaderTabs extends StatelessWidget {
  const _HeaderTabs({required this.hasNotification, this.onTapNotification});

  final bool hasNotification;
  final VoidCallback? onTapNotification;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.headingH1.copyWith(
      color: AppColors.neutralsBackground,
    );

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.only(left: 22, right: 14),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing1),
              child: Text('홈', style: style),
            ),
            const SizedBox(width: AppSpacing.spacing1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing1),
              child: Opacity(opacity: 0.5, child: Text('Q&A', style: style)),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onTapNotification,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 24,
                height: 24,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    SvgPicture.asset('assets/home/bell.svg', width: 24, height: 24),
                    if (hasNotification)
                      Positioned(
                        left: 16,
                        top: 0.5,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.statusWarning,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 30min | 스파이크 방지
class _SuggestionChips extends StatelessWidget {
  const _SuggestionChips();

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodySmM.copyWith(color: Colors.white);
    return Row(
      children: [
        Opacity(
          opacity: 0.5,
          child: Row(
            children: [
              SvgPicture.asset('assets/home/run.svg', width: 20, height: 20),
              const SizedBox(width: AppSpacing.spacing05),
              Text('30min', style: style),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.spacing2),
        const Opacity(
          opacity: 0.25,
          child: Text(
            '|',
            style: TextStyle(
              fontFamily: AppTypography.fontFamilySans,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.spacing2),
        SvgPicture.asset('assets/home/spike.svg', width: 16, height: 16),
        const SizedBox(width: AppSpacing.spacing05),
        Opacity(opacity: 0.5, child: Text('스파이크 방지', style: style)),
      ],
    );
  }
}
