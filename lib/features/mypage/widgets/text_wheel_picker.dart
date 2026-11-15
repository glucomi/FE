import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/widgets/ruler_picker.dart';

/// 휠 피커 한 열 설정 (값 목록 + 표시 형식)
class TextWheelColumn {
  const TextWheelColumn({
    required this.key,
    required this.width,
    required this.values,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  final Key key;
  final double width;
  final List<int> values;
  final int value;
  final String Function(int value) label;
  final ValueChanged<int> onChanged;
}

/// 생년월일 수정 휠 피커 (2002년 1월 18일)
class TextWheelPicker extends StatelessWidget {
  const TextWheelPicker({super.key, required this.columns});

  final List<TextWheelColumn> columns;

  static const double itemExtent = 38;
  static const int visibleItems = 5;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: itemExtent * visibleItems,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.neutralsSurface,
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final column in columns) ...[
                if (column != columns.first)
                  const SizedBox(width: AppSpacing.spacing2),
                _TextWheel(key: column.key, column: column),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

TextStyle _styleForDistance(int distance) => switch (distance) {
  0 => const TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSize3xl,
    fontWeight: FontWeight.w700,
    color: AppColors.foregroundPrimary,
  ),
  1 => const TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSize2xl,
    fontWeight: FontWeight.w400,
    color: AppColors.foregroundQuaternary,
  ),
  _ => const TextStyle(
    fontFamily: AppTypography.fontFamilySans,
    fontSize: AppTypography.fontSizeMd,
    fontWeight: FontWeight.w400,
    color: AppColors.neutralsMuted,
  ),
};

class _TextWheel extends StatefulWidget {
  const _TextWheel({super.key, required this.column});

  final TextWheelColumn column;

  @override
  State<_TextWheel> createState() => _TextWheelState();
}

class _TextWheelState extends State<_TextWheel> {
  late final FixedExtentScrollController _controller;
  late int _selected;

  List<int> get _values => widget.column.values;

  int _indexOf(int value) {
    final index = _values.indexOf(value);
    return index < 0 ? _values.length - 1 : index;
  }

  @override
  void initState() {
    super.initState();
    _selected = _indexOf(widget.column.value);
    _controller = FixedExtentScrollController(initialItem: _selected);
  }

  @override
  void didUpdateWidget(covariant _TextWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _indexOf(widget.column.value);
    if (index != _selected) {
      _selected = index;
      // 월·일 개수가 줄어 값이 바뀐 경우: 콜백이 연쇄되지 않게 바로 이동
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpToItem(index);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.column.width,
      child: ScrollConfiguration(
        behavior: pickerScrollBehavior(context),
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: TextWheelPicker.itemExtent,
          diameterRatio: 100,
          physics: const FixedExtentScrollPhysics(),
          onSelectedItemChanged: (index) {
            if (index < 0 || index >= _values.length) return;
            setState(() => _selected = index);
            widget.column.onChanged(_values[index]);
          },
          childDelegate: ListWheelChildBuilderDelegate(
            childCount: _values.length,
            builder: (context, index) => Center(
              child: Text(
                widget.column.label(_values[index]),
                maxLines: 1,
                softWrap: false,
                style: _styleForDistance((index - _selected).abs()),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
