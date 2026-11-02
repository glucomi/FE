import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/exercise/exercise_models.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

/// 오후 02:03
String formatFieldTime(DateTime t) {
  final period = t.hour < 12 ? '오전' : '오후';
  final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
  return '$period ${h12.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}

/// 필드 라벨 (필수 항목이면 오른쪽에 초록 점)
class ExerciseFieldLabel extends StatelessWidget {
  const ExerciseFieldLabel(this.text, {super.key, this.isRequired = false});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: AppTypography.labelMeta.copyWith(
            color: AppColors.foregroundPrimary,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: AppSpacing.spacing05),
          SvgPicture.asset(
            'assets/exercise/required_mark.svg',
            width: 8,
            height: 8,
          ),
        ],
      ],
    );
  }
}

/// Figma COM-03 (시간): 라벨 + 48px 선택 박스
class ExerciseTimeField extends StatelessWidget {
  const ExerciseTimeField({
    super.key,
    required this.time,
    this.onTap,
    this.label = '시간',
  });

  final DateTime time;

  /// 없으면 탭할 수 없음
  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = formatFieldTime(time);
    return Semantics(
      button: onTap != null,
      label: '$label $text',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExerciseFieldLabel(label),
            const SizedBox(height: AppSpacing.spacing2),
            Container(
              height: AppSpacing.controlHeightLg,
              padding: const EdgeInsets.all(AppSpacing.spacing2),
              decoration: BoxDecoration(
                color: AppColors.neutralsBackground,
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/exercise/time.svg',
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: AppSpacing.spacing1),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.bodySmM.copyWith(
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 시간 선택 바텀시트 (오전/오후 · 시 · 분). 선택 완료 시 [initial] 날짜에 시각만 바꿔 돌려줌
///
/// COM-03 선택 UI 가 정책·디자인에 없어 날짜 시트와 같은 틀로 구성 (확인 필요)
Future<DateTime?> showExerciseTimeSheet(
  BuildContext context, {
  required DateTime initial,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: (context) => _ExerciseTimeSheet(initial: initial),
  );
}

class _ExerciseTimeSheet extends StatefulWidget {
  const _ExerciseTimeSheet({required this.initial});

  final DateTime initial;

  @override
  State<_ExerciseTimeSheet> createState() => _ExerciseTimeSheetState();
}

class _ExerciseTimeSheetState extends State<_ExerciseTimeSheet> {
  static const double _itemExtent = 40;

  late bool _pm = widget.initial.hour >= 12;
  late int _hour12 = widget.initial.hour % 12 == 0 ? 12 : widget.initial.hour % 12;
  late int _minute = widget.initial.minute;

  DateTime get _picked {
    final hour = (_hour12 % 12) + (_pm ? 12 : 0);
    final d = widget.initial;
    return DateTime(d.year, d.month, d.day, hour, _minute);
  }

  Widget _wheel({
    required Key key,
    required int count,
    required int initialIndex,
    required String Function(int) label,
    required ValueChanged<int> onChanged,
    bool looping = false,
  }) {
    final style = AppTypography.bodyLgM.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Expanded(
      child: CupertinoPicker(
        key: key,
        itemExtent: _itemExtent,
        looping: looping,
        selectionOverlay: const SizedBox.shrink(),
        scrollController: FixedExtentScrollController(initialItem: initialIndex),
        onSelectedItemChanged: onChanged,
        children: [
          for (var i = 0; i < count; i++)
            Center(child: Text(label(i), style: style)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      bottomPadding: AppSpacing.spacing2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '시간 선택',
            style: AppTypography.headingH3.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          SizedBox(
            height: _itemExtent * 5,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 가운데 선택 줄
                Container(
                  height: _itemExtent,
                  margin: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neutralsSurface,
                    borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                  ),
                ),
                Row(
                  children: [
                    _wheel(
                      key: const ValueKey('exercise-time-period'),
                      count: 2,
                      initialIndex: _pm ? 1 : 0,
                      label: (i) => i == 0 ? '오전' : '오후',
                      onChanged: (i) => _pm = i == 1,
                    ),
                    _wheel(
                      key: const ValueKey('exercise-time-hour'),
                      count: 12,
                      initialIndex: _hour12 - 1,
                      label: (i) => (i + 1).toString().padLeft(2, '0'),
                      onChanged: (i) => _hour12 = i + 1,
                      looping: true,
                    ),
                    _wheel(
                      key: const ValueKey('exercise-time-minute'),
                      count: 60,
                      initialIndex: _minute,
                      label: (i) => i.toString().padLeft(2, '0'),
                      onChanged: (i) => _minute = i,
                      looping: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          AppButton(
            key: const ValueKey('exercise-time-done'),
            label: '선택 완료',
            onPressed: () => Navigator.of(context).pop(_picked),
          ),
        ],
      ),
    );
  }
}

/// + 운동 추가하기 (MO-EXERCISE-020 이동)
class ExerciseAddButton extends StatelessWidget {
  const ExerciseAddButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '운동 추가하기',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('exercise-add'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: AppSpacing.controlHeightLg,
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderDefault),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/exercise/plus_20.svg',
                width: 20,
                height: 20,
              ),
              const SizedBox(width: AppSpacing.spacing1),
              Text(
                '운동 추가하기',
                style: AppTypography.btnMd.copyWith(
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

/// 추가된 운동 항목: 운동명 · 소모 칼로리 · 운동 시간(분) 입력 · 삭제
class ExerciseEntryTile extends StatefulWidget {
  const ExerciseEntryTile({
    super.key,
    required this.entry,
    this.enabled = true,
    this.onMinutesChanged,
    this.onRemove,
  });

  final ExerciseEntry entry;

  /// false 면 시간 입력·삭제 불가 (등록후 조회 상태)
  final bool enabled;
  final ValueChanged<int>? onMinutesChanged;
  final VoidCallback? onRemove;

  @override
  State<ExerciseEntryTile> createState() => _ExerciseEntryTileState();
}

class _ExerciseEntryTileState extends State<ExerciseEntryTile> {
  late final TextEditingController _controller = TextEditingController(
    text: _textOf(widget.entry.minutes),
  );

  static String _textOf(int minutes) => minutes > 0 ? '$minutes' : '';

  @override
  void didUpdateWidget(covariant ExerciseEntryTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    final current = int.tryParse(_controller.text) ?? 0;
    if (current != widget.entry.minutes) {
      _controller.text = _textOf(widget.entry.minutes);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final valueStyle = AppTypography.bodyMdM.copyWith(
      color: AppColors.foregroundPrimary,
    );

    return Container(
      height: 63,
      padding: const EdgeInsets.only(
        left: AppSpacing.spacing5,
        right: AppSpacing.spacing2,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.spacing1),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: valueStyle,
                  ),
                  const SizedBox(height: AppSpacing.spacing05),
                  Text(
                    '${entry.kcal} kcal',
                    key: const ValueKey('exercise-entry-kcal'),
                    style: AppTypography.labelBadge.copyWith(
                      color: AppColors.foregroundQuaternary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Select: 운동 시간 (분)
          Container(
            width: 56,
            padding: const EdgeInsets.all(AppSpacing.spacing2),
            decoration: BoxDecoration(
              color: AppColors.neutralsSurface,
              border: Border.all(color: AppColors.borderDefault),
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    key: const ValueKey('exercise-entry-minutes'),
                    controller: _controller,
                    enabled: widget.enabled,
                    // 숫자만 입력 (숫자 키패드)
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(
                        ExercisePolicy.maxMinuteDigits,
                      ),
                    ],
                    textAlign: TextAlign.right,
                    style: valueStyle,
                    cursorColor: AppColors.accentsBrand,
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                    onChanged: (v) =>
                        widget.onMinutesChanged?.call(int.tryParse(v) ?? 0),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing1),
                Text(
                  '분',
                  style: AppTypography.bodySmM.copyWith(
                    color: AppColors.foregroundQuaternary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Semantics(
            button: true,
            label: '${entry.exercise.name} 삭제',
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('exercise-entry-remove'),
              onTap: widget.enabled ? widget.onRemove : null,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: AppSpacing.controlHeightSm,
                height: AppSpacing.controlHeightSm,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/exercise/remove_16.svg',
                    width: 16,
                    height: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma COM-04 메모 (선택 입력, 최대 1000자)
class ExerciseMemoField extends StatelessWidget {
  const ExerciseMemoField({
    super.key,
    required this.controller,
    this.enabled = true,
    // MO-EXERCISE-010 정책 보조문구 그대로 (디자인은 '운동과/혈당과…' — 확인 필요)
    this.hintText = '복용과 관련한 내용을 메모해보세요.',
  });

  final TextEditingController controller;
  final bool enabled;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ExerciseFieldLabel('메모'),
        const SizedBox(height: AppSpacing.spacing2),
        Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
            vertical: AppSpacing.spacing3,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: TextField(
            key: const ValueKey('exercise-memo'),
            controller: controller,
            enabled: enabled,
            minLines: 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            inputFormatters: [
              LengthLimitingTextInputFormatter(ExercisePolicy.maxMemoLength),
            ],
            style: style,
            cursorColor: AppColors.accentsBrand,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hintText,
              hintStyle: style.copyWith(color: AppColors.foregroundQuaternary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing2),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) => SizedBox(
            width: double.infinity,
            child: Text(
              '${value.text.characters.length}/${ExercisePolicy.maxMemoLength}',
              textAlign: TextAlign.right,
              style: AppTypography.bodySmR.copyWith(
                color: AppColors.foregroundTertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
