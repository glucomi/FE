import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';
import 'package:glucomi/shared/widgets/app_radio.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// 기록 화면 바텀시트 공통 호출 (DIM 70%, 여백 탭 시 닫힘)
Future<T?> showRecordSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: builder,
  );
}

/// 시트 안쪽 좌우 여백(16)을 무시하고 시트 폭 전체로 그림 (리스트 · 하단 버튼 영역)
class _FullBleed extends StatelessWidget {
  const _FullBleed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth + AppSpacing.spacing4 * 2;
        return OverflowBox(
          minWidth: width,
          maxWidth: width,
          fit: OverflowBoxFit.deferToChild,
          child: child,
        );
      },
    );
  }
}

/// 시트 제목 + (선택) 오른쪽 외곽선 버튼
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.controlHeightSm,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.headingH3.copyWith(
                color: AppColors.foregroundPrimary,
              ),
            ),
          ),
          if (actionLabel != null)
            Semantics(
              button: true,
              label: actionLabel,
              excludeSemantics: true,
              child: GestureDetector(
                key: const ValueKey('record-sheet-action'),
                onTap: onAction,
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
                        actionLabel!,
                        style: AppTypography.btnSm.copyWith(
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 라디오 리스트 한 줄 (57px): 제목 · 보조정보 + 오른쪽 라디오
class RecordRadioTile extends StatelessWidget {
  const RecordRadioTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = subtitle != null && subtitle!.isNotEmpty;
    return Semantics(
      button: true,
      selected: selected,
      label: hasSubtitle ? '$title $subtitle' : title,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 57,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing5),
          decoration: const BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border(bottom: BorderSide(color: AppColors.borderDefault)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyLgM.copyWith(
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                    if (hasSubtitle) ...[
                      const SizedBox(width: AppSpacing.spacing2),
                      Container(
                        width: 2,
                        height: 2,
                        decoration: const BoxDecoration(
                          color: AppColors.foregroundTertiary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing2),
                      Flexible(
                        child: Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMdM.copyWith(
                            color: AppColors.foregroundTertiary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.spacing2),
              AppRadio(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

/// 하단 선택 완료 버튼 영역 (COM-07, 시트 폭 전체)
class _SheetDoneBar extends StatelessWidget {
  const _SheetDoneBar({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _FullBleed(
      child: BottomActionBar(
        key: const ValueKey('record-sheet-done'),
        label: '선택 완료',
        onPressed: onPressed,
      ),
    );
  }
}

/// 단일 선택 라디오 시트 (예: COM-POP-09 약 종류 선택).
/// 선택 완료를 누르면 고른 index, 그냥 닫으면 null. 미선택 시 선택 완료 비활성
Future<int?> showRecordOptionSheet(
  BuildContext context, {
  required String title,
  required List<String> options,
  int? selected,
}) {
  return showRecordSheet<int>(
    context,
    builder: (_) =>
        RecordOptionSheet(title: title, options: options, selected: selected),
  );
}

class RecordOptionSheet extends StatefulWidget {
  const RecordOptionSheet({
    super.key,
    required this.title,
    required this.options,
    this.selected,
  });

  final String title;
  final List<String> options;
  final int? selected;

  @override
  State<RecordOptionSheet> createState() => _RecordOptionSheetState();
}

class _RecordOptionSheetState extends State<RecordOptionSheet> {
  late int? _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      bottomPadding: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(title: widget.title),
          const SizedBox(height: AppSpacing.spacing4),
          _FullBleed(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < widget.options.length; i++)
                  RecordRadioTile(
                    key: ValueKey('record-option-$i'),
                    title: widget.options[i],
                    selected: _selected == i,
                    onTap: () => setState(() => _selected = i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          _SheetDoneBar(
            onPressed: _selected == null
                ? null
                : () => Navigator.of(context).pop(_selected),
          ),
        ],
      ),
    );
  }
}

/// 저장해 둔 항목 한 개 (예: 복용약 = 약 종류 · 제품명)
@immutable
class SavedItemOption {
  const SavedItemOption({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}

/// [showSavedItemSheet] 결과: 고른 항목 index 또는 새 항목 추가 요청
@immutable
class SavedItemSheetResult {
  const SavedItemSheetResult.selected(int this.index) : addRequested = false;
  const SavedItemSheetResult.add() : index = null, addRequested = true;

  final int? index;
  final bool addRequested;
}

/// 저장 목록에서 하나 고르는 시트 (예: COM-POP-07 복용약 선택).
/// - 오른쪽 위 [addLabel] 버튼 → [SavedItemSheetResult.add]
/// - 목록이 없으면 [emptyTitle] / [emptyMessage] 표시
/// - 한 번에 하나만 선택, 미선택 시 선택 완료 비활성
Future<SavedItemSheetResult?> showSavedItemSheet(
  BuildContext context, {
  required String title,
  required String addLabel,
  required String countLabel,
  required String emptyTitle,
  required String emptyMessage,
  required List<SavedItemOption> items,
  int? selected,
}) {
  return showRecordSheet<SavedItemSheetResult>(
    context,
    builder: (_) => SavedItemSheet(
      title: title,
      addLabel: addLabel,
      countLabel: countLabel,
      emptyTitle: emptyTitle,
      emptyMessage: emptyMessage,
      items: items,
      selected: selected,
    ),
  );
}

class SavedItemSheet extends StatefulWidget {
  const SavedItemSheet({
    super.key,
    required this.title,
    required this.addLabel,
    required this.countLabel,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.items,
    this.selected,
  });

  final String title;
  final String addLabel;
  final String countLabel;
  final String emptyTitle;
  final String emptyMessage;
  final List<SavedItemOption> items;
  final int? selected;

  @override
  State<SavedItemSheet> createState() => _SavedItemSheetState();
}

class _SavedItemSheetState extends State<SavedItemSheet> {
  // Figma: 목록 영역 최대 높이 280 (넘으면 스크롤)
  static const double _listMaxHeight = 280;

  late int? _selected = widget.selected;

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return AppBottomSheetFrame(
      bottomPadding: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(
            title: widget.title,
            actionLabel: widget.addLabel,
            onAction: () =>
                Navigator.of(context).pop(const SavedItemSheetResult.add()),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          _FullBleed(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: _listMaxHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.spacing3,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _CountChip(
                          label: widget.countLabel,
                          count: items.length,
                        ),
                      ),
                    ),
                    if (items.isEmpty)
                      _EmptyMessage(
                        title: widget.emptyTitle,
                        message: widget.emptyMessage,
                      )
                    else
                      for (var i = 0; i < items.length; i++)
                        RecordRadioTile(
                          key: ValueKey('saved-item-$i'),
                          title: items[i].title,
                          subtitle: items[i].subtitle,
                          selected: _selected == i,
                          onTap: () => setState(() => _selected = i),
                        ),
                  ],
                ),
              ),
            ),
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.spacing4),
            _SheetDoneBar(
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(
                      context,
                    ).pop(SavedItemSheetResult.selected(_selected!)),
            ),
          ] else
            const SizedBox(height: AppSpacing.spacing4),
        ],
      ),
    );
  }
}

/// 저장된 복용약 N개
class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.controlHeightSm,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing3),
      decoration: BoxDecoration(
        color: AppColors.foregroundPrimary,
        borderRadius: BorderRadius.circular(AppRadius.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.btnSm.copyWith(
              color: AppColors.foregroundOnAccent,
            ),
          ),
          const SizedBox(width: AppSpacing.spacing2),
          Text(
            '$count개',
            style: AppTypography.btnSm.copyWith(color: AppColors.accentsBrand),
          ),
        ],
      ),
    );
  }
}

/// 목록이 비었을 때 두 줄 안내
class RecordEmptyMessage extends StatelessWidget {
  const RecordEmptyMessage({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing16,
      ),
      child: RecordEmptyMessage(title: title, message: message),
    );
  }
}
