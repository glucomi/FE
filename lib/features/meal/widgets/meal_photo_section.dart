import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/widgets/meal_form_widgets.dart';

/// MO-MEAL-040 사진 추가하기 (COM-05, 선택 항목)
///
/// 사진이 없으면 추가 버튼만, 있으면 좌우로 넘기는 사진 + 순서 표시(1/3) +
/// 개별 삭제 + 음식칩. 마지막 사진에서 첫 사진으로 순환하지 않음
class MealPhotoSection extends StatefulWidget {
  const MealPhotoSection({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
    this.foodNames = const {},
    this.onFoodTap,
  });

  final List<MealPhoto> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  /// 음식칩 이름 (음식 id → 이름). 메뉴에서 빠진 음식은 칩을 숨김
  final Map<String, String> foodNames;
  final ValueChanged<String>? onFoodTap;

  @override
  State<MealPhotoSection> createState() => _MealPhotoSectionState();
}

class _MealPhotoSectionState extends State<MealPhotoSection> {
  final _pageController = PageController();
  int _page = 0;

  static final Color _overlay = AppColors.foregroundPrimary.withValues(alpha: 0.7);

  @override
  void didUpdateWidget(covariant MealPhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = widget.photos.length;
    if (count > oldWidget.photos.length && _pageController.hasClients) {
      // 새로 추가한 사진으로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_pageController.hasClients) _pageController.jumpToPage(count - 1);
      });
    } else if (_page >= count && count > 0) {
      _page = count - 1;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ③ 선택 항목
        const MealFieldLabel(label: '사진 추가하기(선택)'),
        const SizedBox(height: AppSpacing.spacing2),
        if (photos.isNotEmpty) ...[
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderDefault),
                borderRadius: BorderRadius.circular(AppRadius.radiusLg),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    key: const ValueKey('meal-photo-pager'),
                    controller: _pageController,
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) =>
                        Image.memory(photos[i].bytes, fit: BoxFit.cover),
                  ),
                  Positioned(left: 16, top: 20, child: _indicator(photos.length)),
                  Positioned(
                    right: 15,
                    top: 19,
                    child: Semantics(
                      button: true,
                      label: '사진 삭제',
                      child: GestureDetector(
                        key: const ValueKey('meal-photo-remove'),
                        onTap: () => widget.onRemove(_page.clamp(0, photos.length - 1)),
                        child: Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _overlay,
                            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                          ),
                          child: SvgPicture.asset(
                            'assets/meal/photo_close.svg',
                            width: 16,
                            height: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  ?_foodChip(photos[_page.clamp(0, photos.length - 1)]),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing2),
        ],
        MealOutlineAddButton(
          key: const ValueKey('meal-photo-add'),
          label: '사진 추가하기',
          onTap: widget.onAdd,
        ),
      ],
    );
  }

  Widget _indicator(int total) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.foregroundPrimary.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppRadius.radiusFull),
      ),
      child: Text(
        '${_page + 1}/$total',
        key: const ValueKey('meal-photo-indicator'),
        style: AppTypography.bodyMdR.copyWith(
          color: AppColors.foregroundOnAccent,
        ),
      ),
    );
  }

  Widget? _foodChip(MealPhoto photo) {
    final id = photo.foodId;
    final name = id == null ? null : widget.foodNames[id];
    if (id == null || name == null) return null;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 138,
      child: Center(
        child: GestureDetector(
          key: ValueKey('meal-photo-chip-$id'),
          onTap: () => widget.onFoodTap?.call(id),
          child: Container(
            height: 32,
            padding: const EdgeInsets.only(
              left: AppSpacing.spacing5,
              right: AppSpacing.spacing3,
            ),
            decoration: BoxDecoration(
              color: _overlay,
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTypography.btnSm.copyWith(
                    color: AppColors.foregroundOnAccent,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing05),
                SvgPicture.asset(
                  'assets/meal/chevron_right_white_16.svg',
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
