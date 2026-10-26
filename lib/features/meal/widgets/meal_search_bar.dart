import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// 음식명 검색창 (SearchBar)
class MealSearchBar extends StatelessWidget {
  const MealSearchBar({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final textStyle = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );

    return SizedBox(
      height: 44,
      child: Center(
        child: Container(
          height: AppSpacing.controlHeightMd,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing3),
          decoration: BoxDecoration(
            color: AppColors.neutralsSurface,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            children: [
              SvgPicture.asset('assets/meal/search.svg', width: 24, height: 24),
              const SizedBox(width: AppSpacing.spacing2),
              Expanded(
                child: TextField(
                  key: const ValueKey('meal-search-field'),
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  textInputAction: TextInputAction.search,
                  // MO-MEAL-010: 검색어 최대 50자
                  inputFormatters: [LengthLimitingTextInputFormatter(50)],
                  style: textStyle,
                  cursorColor: AppColors.accentsBrand,
                  decoration: InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    hintText: '음식명을 입력해 주세요',
                    hintStyle: textStyle.copyWith(
                      color: AppColors.foregroundQuaternary,
                    ),
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return Semantics(
                    button: true,
                    label: '검색어 지우기',
                    child: GestureDetector(
                      key: const ValueKey('meal-search-clear'),
                      onTap: onClear,
                      behavior: HitTestBehavior.opaque,
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/meal/clear.svg',
                            width: 12,
                            height: 12,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 즐겨찾기 / 최근 먹은 음식 / 직접 등록 탭 (Tabs)
class MealTabs extends StatelessWidget {
  const MealTabs({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (i, label) in labels.indexed)
          Expanded(
            child: GestureDetector(
              key: ValueKey('meal-tab-$i'),
              onTap: () => onSelect(i),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 37,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: i == selectedIndex
                        // Figma 렌더 기준 선택 탭 밑줄은 진한 색
                        ? const BorderSide(
                            color: AppColors.foregroundPrimary,
                            width: AppTokens.borderWidthThick,
                          )
                        : const BorderSide(color: AppColors.borderDefault),
                  ),
                ),
                child: Text(
                  label,
                  style: AppTypography.btnMd.copyWith(
                    color: i == selectedIndex
                        ? AppColors.foregroundPrimary
                        : AppColors.foregroundQuaternary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 목록이 비었을 때 안내 문구
class MealEmptyMessage extends StatelessWidget {
  const MealEmptyMessage({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTypography.bodyMdM.copyWith(
              color: AppColors.foregroundSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing05),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmR.copyWith(
              color: AppColors.foregroundTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
