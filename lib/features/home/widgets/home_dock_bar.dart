import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

enum HomeTab {
  camera('카메라', 'assets/home/dock_camera.svg'),
  home('홈', 'assets/home/dock_home.svg'),
  farm('농장', 'assets/home/dock_farm.svg'),
  myPage('마이페이지', 'assets/home/dock_mypage.svg');

  const HomeTab(this.label, this.iconAsset);

  final String label;
  final String iconAsset;
}

/// 하단 탭바 (Figma Dock Bar)
class HomeDockBar extends StatelessWidget {
  const HomeDockBar({super.key, required this.current, this.onSelect});

  final HomeTab current;
  final ValueChanged<HomeTab>? onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.foregroundOnAccent,
        border: Border(top: BorderSide(color: AppColors.neutralsSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final tab in HomeTab.values)
              Expanded(
                child: GestureDetector(
                  key: ValueKey('dock-${tab.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onSelect?.call(tab),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: AppSpacing.spacing2,
                      bottom: AppSpacing.spacing1,
                      left: AppSpacing.spacing2,
                      right: AppSpacing.spacing2,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SvgPicture.asset(
                          tab.iconAsset,
                          width: 24,
                          height: 24,
                          colorFilter: ColorFilter.mode(
                            tab == current
                                ? AppColors.accentsBrand
                                : AppColors.neutralsMuted,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.spacing1),
                        Text(
                          tab.label,
                          style: AppTypography.labelBadge.copyWith(
                            color: tab == current
                                ? AppColors.accentsBrand
                                : AppColors.foregroundQuaternary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
