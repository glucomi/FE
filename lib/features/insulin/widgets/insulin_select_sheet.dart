import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/features/insulin/widgets/insulin_fields.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';
import 'package:glucomi/shared/widgets/app_button.dart';
import 'package:glucomi/shared/widgets/app_radio.dart';
import 'package:glucomi/shared/widgets/record/record_sheets.dart';

/// 인슐린 선택 바텀시트에서 고른 동작
@immutable
class InsulinSelectSheetResult {
  const InsulinSelectSheetResult.selected(MyInsulin this.insulin)
    : addNew = false;
  const InsulinSelectSheetResult.addNew() : insulin = null, addNew = true;

  final MyInsulin? insulin;

  /// '새 인슐린' 을 눌렀을 때
  final bool addNew;
}

/// 인슐린 선택 바텀시트 (COM-POP-06). 여백을 누르면 null
Future<InsulinSelectSheetResult?> showInsulinSelectSheet(
  BuildContext context, {
  required List<MyInsulin> insulins,
  String? selectedId,
}) {
  return showRecordSheet<InsulinSelectSheetResult>(
    context,
    builder: (context) =>
        InsulinSelectSheet(insulins: insulins, selectedId: selectedId),
  );
}

class InsulinSelectSheet extends StatefulWidget {
  const InsulinSelectSheet({
    super.key,
    required this.insulins,
    this.selectedId,
  });

  final List<MyInsulin> insulins;
  final String? selectedId;

  @override
  State<InsulinSelectSheet> createState() => _InsulinSelectSheetState();
}

class _InsulinSelectSheetState extends State<InsulinSelectSheet> {
  /// Figma 인슐린 리스트 영역 높이
  static const double _listMaxHeight = 280;

  late String? _selectedId =
      widget.insulins.any((m) => m.id == widget.selectedId)
      ? widget.selectedId
      : null;

  MyInsulin? get _selected {
    for (final m in widget.insulins) {
      if (m.id == _selectedId) return m;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final empty = widget.insulins.isEmpty;
    return AppBottomSheetFrame(
      horizontalPadding: 0,
      bottomPadding: empty ? AppSpacing.spacing4 : AppSpacing.spacing2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '인슐린 선택',
                    style: AppTypography.headingH3.copyWith(
                      color: AppColors.foregroundPrimary,
                    ),
                  ),
                ),
                _AddNewButton(
                  onTap: () =>
                      Navigator.of(context)
                          .pop(const InsulinSelectSheetResult.addNew()),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing3,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _CountChip(count: widget.insulins.length),
            ),
          ),
          if (empty)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing4,
                vertical: AppSpacing.spacing16,
              ),
              child: InsulinEmptyMessage(),
            )
          else ...[
            const SizedBox(height: AppSpacing.spacing2),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _listMaxHeight),
              child: ListView.separated(
                key: const ValueKey('insulin-select-list'),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.spacing4,
                  vertical: AppSpacing.spacing2,
                ),
                itemCount: widget.insulins.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.spacing2),
                itemBuilder: (context, index) {
                  final insulin = widget.insulins[index];
                  return InsulinListTile(
                    key: ValueKey('insulin-select-${insulin.id}'),
                    insulin: insulin,
                    selected: insulin.id == _selectedId,
                    onTap: () => setState(() => _selectedId = insulin.id),
                  );
                },
              ),
            ),
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.spacing4,
              ),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderDefault)),
              ),
              child: AppButton(
                key: const ValueKey('insulin-select-done'),
                label: '선택 완료',
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context)
                          .pop(InsulinSelectSheetResult.selected(_selected!)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// INSULINE-LIST: 라디오 + 제품명·투여량 (좌) + 분류 (우)
class InsulinListTile extends StatelessWidget {
  const InsulinListTile({
    super.key,
    required this.insulin,
    required this.selected,
    required this.onTap,
  });

  final MyInsulin insulin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = AppTypography.bodyMdM.copyWith(
      color: AppColors.foregroundTertiary,
    );
    final dose = InsulinDosePolicy.formatWithUnit(insulin.dose);
    return Semantics(
      button: true,
      selected: selected,
      label: '${insulin.product.name} $dose ${insulin.product.category.label}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing5,
            vertical: AppSpacing.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(AppRadius.radiusLg),
          ),
          child: Row(
            children: [
              AppRadio(selected: selected),
              const SizedBox(width: AppSpacing.spacing2),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        insulin.product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyLgM.copyWith(
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.spacing2),
                    SvgPicture.asset(
                      'assets/insulin/dot.svg',
                      width: 2,
                      height: 2,
                    ),
                    const SizedBox(width: AppSpacing.spacing2),
                    Text(dose, style: meta),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(insulin.product.category.label, style: meta),
            ],
          ),
        ),
      ),
    );
  }
}

/// 저장된 인슐린 N개 (검정 칩)
class _CountChip extends StatelessWidget {
  const _CountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.controlHeightSm,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing3),
      decoration: BoxDecoration(
        color: AppColors.gray900,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '저장된 인슐린',
            style: AppTypography.btnSm.copyWith(
              color: AppColors.foregroundOnAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing2),
          Text(
            '$count개',
            key: const ValueKey('insulin-select-count'),
            style: AppTypography.btnSm.copyWith(color: AppColors.accentsBrand),
          ),
        ],
      ),
    );
  }
}

/// + 새 인슐린 (흰 배경 테두리 버튼, 높이 32)
class _AddNewButton extends StatelessWidget {
  const _AddNewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '새 인슐린',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('insulin-select-add'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: AppSpacing.controlHeightSm,
          padding: const EdgeInsets.only(
            left: AppSpacing.spacing3,
            right: AppSpacing.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/record/plus_16.svg',
                width: 16,
                height: 16,
              ),
              const SizedBox(width: AppSpacing.spacing05),
              Text(
                '새 인슐린',
                style: AppTypography.btnSm.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
