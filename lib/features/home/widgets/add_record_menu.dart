import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// + 버튼으로 추가할 수 있는 기록 종류 (Figma 메뉴 순서)
enum AddRecordType {
  food('식단', 'assets/home/memo_food.svg'),
  weight('체중', 'assets/home/memo_weight.svg'),
  glucose('혈당', 'assets/home/menu_glucose.svg'),
  insulin('인슐린', 'assets/home/memo_insulin.svg'),
  medicine('복약', 'assets/home/memo_medicine.svg'),
  exercise('운동', 'assets/home/memo_exercise.svg'),
  memo('메모', 'assets/home/memo_note.svg');

  const AddRecordType(this.label, this.iconAsset);

  final String label;
  final String iconAsset;
}

/// 기록 추가 메뉴를 띄움. [fabRect] 는 Navigator 오버레이 기준 + 버튼 위치
/// (닫기 버튼이 같은 자리에 뜸)
Future<AddRecordType?> showAddRecordMenu(
  BuildContext context, {
  required Rect fabRect,
}) {
  return showGeneralDialog<AddRecordType>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '기록 추가 닫기',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (context, animation, _) =>
        AddRecordMenu(fabRect: fabRect, animation: animation),
  );
}

class AddRecordMenu extends StatelessWidget {
  const AddRecordMenu({
    super.key,
    required this.fabRect,
    required this.animation,
  });

  final Rect fabRect;
  final Animation<double> animation;

  /// 메뉴가 열렸을 때 닫기 버튼 색 (Figma 값)
  static const Color _openedFabColor = Color(0xFF00BBA6);

  /// 메뉴 목록과 닫기 버튼 사이 간격
  static const double _menuGap = 18;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOut);

    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _buildLayout(context, constraints.biggest, curved),
      ),
    );
  }

  Widget _buildLayout(
    BuildContext context,
    Size screen,
    Animation<double> curved,
  ) {
    return Stack(
      children: [
        // DIM: 검정 70% + 블러 5
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: FadeTransition(
              opacity: curved,
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: const ColoredBox(color: Color(0xB3000000)),
              ),
            ),
          ),
        ),
        Positioned(
          right: screen.width - fabRect.right,
          bottom: screen.height - fabRect.top + _menuGap,
          width: 92,
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: Column(
                children: [
                  for (final type in AddRecordType.values) ...[
                    if (type != AddRecordType.values.first)
                      const SizedBox(height: AppSpacing.spacing3),
                    _MenuItem(
                      type: type,
                      onTap: () => Navigator.of(context).pop(type),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: fabRect,
          child: Semantics(
            button: true,
            label: '기록 추가 닫기',
            child: GestureDetector(
              key: const ValueKey('home-add-record-close'),
              onTap: () => Navigator.of(context).pop(),
              child: AnimatedBuilder(
                animation: curved,
                builder: (context, child) => Transform.rotate(
                  angle: curved.value * math.pi / 4,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        AppColors.accentsBrand,
                        _openedFabColor,
                        curved.value,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.md,
                    ),
                    child: child,
                  ),
                ),
                child: SvgPicture.asset(
                  'assets/home/plus.svg',
                  width: 26,
                  height: 26,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.type, required this.onTap});

  final AddRecordType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${type.label} 기록',
      child: GestureDetector(
        key: ValueKey('add-record-${type.name}'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 37,
          // Figma 테두리는 안쪽에 그려지므로 좌우 16 - 테두리 1
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(AppRadius.radiusFull),
            boxShadow: AppShadows.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(type.iconAsset, width: 16, height: 16),
              const SizedBox(width: AppSpacing.spacing15),
              SizedBox(
                width: 38,
                child: Text(
                  type.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: AppTypography.btnMd.copyWith(
                    color: AppColors.foregroundPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
