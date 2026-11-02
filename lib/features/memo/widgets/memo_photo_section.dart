import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/memo/memo_models.dart';

/// Figma COM-05 (사진 추가하기) + 사진이 있으면 COM-06 (사진 카드)
///
/// 메모에서는 COM-06 의 음식 칩을 띄우지 않음 (정책: 음식이 찍혀도 미노출)
class MemoPhotoSection extends StatelessWidget {
  const MemoPhotoSection({
    super.key,
    required this.photos,
    this.onAdd,
    this.onRemove,
    this.label = '사진 추가하기',
  });

  final List<MemoPhoto> photos;

  /// 없으면 추가 버튼을 누를 수 없음
  final VoidCallback? onAdd;

  /// 지금 보고 있는 사진 삭제 (없으면 삭제 버튼 동작 안 함)
  final ValueChanged<int>? onRemove;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppTypography.labelMeta.copyWith(
            color: AppColors.foregroundPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing2),
        if (photos.isNotEmpty) ...[
          MemoPhotoCard(photos: photos, onRemove: onRemove),
          const SizedBox(height: AppSpacing.spacing2),
        ],
        Semantics(
          button: true,
          enabled: onAdd != null,
          label: label,
          excludeSemantics: true,
          child: GestureDetector(
            key: const ValueKey('memo-add-photo'),
            onTap: onAdd,
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: AppSpacing.controlHeightLg,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing5,
              ),
              decoration: BoxDecoration(
                color: AppColors.neutralsBackground,
                border: Border.all(color: AppColors.borderDefault),
                borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    'assets/memo/plus_20.svg',
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: AppSpacing.spacing2),
                  Text(
                    label,
                    style: AppTypography.btnMd.copyWith(
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Figma COM-06 (음식 칩 없음): 정사각형 사진 + 좌상단 n/전체 + 우상단 삭제
class MemoPhotoCard extends StatefulWidget {
  const MemoPhotoCard({super.key, required this.photos, this.onRemove});

  final List<MemoPhoto> photos;
  final ValueChanged<int>? onRemove;

  @override
  State<MemoPhotoCard> createState() => _MemoPhotoCardState();
}

class _MemoPhotoCardState extends State<MemoPhotoCard> {
  final _controller = PageController();
  int _page = 0;

  @override
  void didUpdateWidget(covariant MemoPhotoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final count = widget.photos.length;
    if (count > oldWidget.photos.length) {
      // 새로 추가한 사진(마지막)을 보여줌
      _jumpTo(count - 1);
    } else if (_page >= count && count > 0) {
      _jumpTo(count - 1);
    }
  }

  void _jumpTo(int page) {
    _page = page;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controller.hasClients) _controller.jumpToPage(page);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: PageView.builder(
                key: const ValueKey('memo-photo-pages'),
                controller: _controller,
                itemCount: photos.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) => Image.memory(
                  photos[i].bytes,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
            ),
            // 좌상단 현재/전체
            Positioned(
              left: AppSpacing.spacing4,
              top: AppSpacing.spacing4,
              child: Container(
                height: 31,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing3,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.foregroundPrimary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                ),
                child: Text(
                  '${_page.clamp(0, photos.length - 1) + 1}/${photos.length}',
                  key: const ValueKey('memo-photo-index'),
                  style: AppTypography.bodyMdR.copyWith(
                    color: AppColors.foregroundOnAccent,
                  ),
                ),
              ),
            ),
            // 우상단 삭제
            Positioned(
              right: 15,
              top: 19,
              child: Semantics(
                button: true,
                enabled: widget.onRemove != null,
                label: '사진 삭제',
                child: GestureDetector(
                  key: const ValueKey('memo-photo-remove'),
                  onTap: widget.onRemove == null
                      ? null
                      : () => widget.onRemove!(
                          _page.clamp(0, photos.length - 1),
                        ),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: AppSpacing.controlHeightSm,
                    height: AppSpacing.controlHeightSm,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.foregroundPrimary.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                    ),
                    child: SvgPicture.asset(
                      'assets/memo/photo_delete.svg',
                      width: 16,
                      height: 16,
                    ),
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
