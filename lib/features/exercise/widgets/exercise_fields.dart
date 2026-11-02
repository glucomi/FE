import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/exercise/exercise_models.dart';

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
