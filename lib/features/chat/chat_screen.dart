import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/home/widgets/home_dock_bar.dart';
import 'package:glucomi/features/home/widgets/home_hero.dart';

/// MO-CHAT-010 따당챗 (홈 상단 탭 — MO-HOME-010 2번 '탭 이동')
///
/// 정책서: 기능 미기획, 와이어프레임은 '(a) 기본 - 센서 미연결' 빈 화면만 있음.
/// 홈과 같은 상단 탭·하단 탭바를 두고 본문은 준비 중 안내로 둠
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key, required this.onSelectHomeTab, this.onSelectDock});

  /// 상단 '홈' 탭
  final VoidCallback onSelectHomeTab;

  /// 하단 탭바
  final ValueChanged<HomeTab>? onSelectDock;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      bottomNavigationBar: HomeDockBar(
        current: HomeTab.home,
        onSelect: (tab) {
          if (tab == HomeTab.home) {
            onSelectHomeTab();
          } else {
            onSelectDock?.call(tab);
          }
        },
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: topInset + 200,
            padding: EdgeInsets.only(top: topInset),
            alignment: Alignment.topCenter,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.green600, AppColors.green200, AppColors.neutralsSurface],
              ),
            ),
            child: HomeHeaderTabs(
              current: HomeHeaderTab.chat,
              onSelect: (tab) {
                if (tab == HomeHeaderTab.home) onSelectHomeTab();
              },
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '따당챗을 준비하고 있어요',
                    style: AppTypography.bodyMdM.copyWith(
                      color: AppColors.foregroundSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing1),
                  Text(
                    '혈당·식단 궁금한 점을 곧 물어볼 수 있어요',
                    style: AppTypography.bodySmR.copyWith(
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
