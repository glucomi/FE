import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';
import 'package:glucomi/shared/widgets/app_button.dart';
import 'package:glucomi/shared/widgets/record/record_sheets.dart';

/// 인슐린 종류 선택 바텀시트 (COM-POP-08). 선택 완료를 누르면 고른 종류, 여백을 누르면 null
Future<InsulinProduct?> showInsulinTypeSheet(
  BuildContext context, {
  InsulinProduct? selected,
}) {
  return showRecordSheet<InsulinProduct>(
    context,
    builder: (context) => InsulinTypeSheet(selected: selected),
  );
}

/// 분류 헤더 + 제품명 라디오 리스트 (단일 선택)
class InsulinTypeSheet extends StatefulWidget {
  const InsulinTypeSheet({super.key, this.selected});

  final InsulinProduct? selected;

  @override
  State<InsulinTypeSheet> createState() => _InsulinTypeSheetState();
}

class _InsulinTypeSheetState extends State<InsulinTypeSheet> {
  /// Figma 인슐린 리스트 영역 높이
  static const double _listHeight = 480;

  late InsulinProduct? _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final groups = InsulinCatalog.byCategory;
    // 화면이 작으면 시트가 넘치지 않게 리스트를 줄임
    final listHeight = math.min(
      _listHeight,
      MediaQuery.sizeOf(context).height * 0.6,
    );

    return AppBottomSheetFrame(
      horizontalPadding: 0,
      bottomPadding: AppSpacing.spacing2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing4,
            ),
            child: Text(
              '인슐린 선택',
              style: AppTypography.headingH3.copyWith(
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          SizedBox(
            height: listHeight,
            child: ColoredBox(
              color: AppColors.neutralsSurface,
              child: ListView.separated(
                key: const ValueKey('insulin-type-list'),
                itemCount: groups.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.spacing2),
                itemBuilder: (context, index) {
                  final entry = groups.entries.elementAt(index);
                  return _CategoryGroup(
                    category: entry.key,
                    products: entry.value,
                    selected: _selected,
                    onSelect: (p) => setState(() => _selected = p),
                  );
                },
              ),
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
              key: const ValueKey('insulin-type-done'),
              label: '선택 완료',
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(_selected),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.category,
    required this.products,
    required this.selected,
    required this.onSelect,
  });

  final InsulinCategory category;
  final List<InsulinProduct> products;
  final InsulinProduct? selected;
  final ValueChanged<InsulinProduct> onSelect;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.neutralsBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.spacing4,
              AppSpacing.spacing3,
              AppSpacing.spacing4,
              0,
            ),
            child: Text(
              category.label,
              style: AppTypography.labelMeta.copyWith(
                color: AppColors.foregroundTertiary,
              ),
            ),
          ),
          for (final product in products)
            RecordRadioTile(
              key: ValueKey('insulin-type-${product.name}'),
              title: product.name,
              selected: product == selected,
              onTap: () => onSelect(product),
            ),
        ],
      ),
    );
  }
}
