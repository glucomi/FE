import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/exercise/exercise_models.dart';
import 'package:glucomi/shared/widgets/app_radio.dart';

/// 운동 목록 섹션 (제목 + 항목들)
class ExerciseOptionSection extends StatelessWidget {
  const ExerciseOptionSection({
    super.key,
    required this.title,
    required this.exercises,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final List<Exercise> exercises;
  final Exercise? selected;
  final ValueChanged<Exercise> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              title,
              style: AppTypography.bodyMdM.copyWith(
                color: AppColors.foregroundQuaternary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing2),
        for (var i = 0; i < exercises.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          ExerciseOptionTile(
            exercise: exercises[i],
            selected: exercises[i] == selected,
            onTap: () => onSelect(exercises[i]),
          ),
        ],
      ],
    );
  }
}

/// 운동 한 항목: 라디오 + 운동명 + 소모칼로리 / 30분
class ExerciseOptionTile extends StatelessWidget {
  const ExerciseOptionTile({
    super.key,
    required this.exercise,
    required this.selected,
    required this.onTap,
  });

  final Exercise exercise;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = '${exercise.kcalPerBase}kcal / ${ExercisePolicy.baseMinutes}분';
    return Semantics(
      button: true,
      selected: selected,
      label: '${exercise.name} $meta',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('exercise-option-${exercise.id}'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 57,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing5),
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
                child: Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyLgM.copyWith(
                    color: AppColors.foregroundPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Text(
                meta,
                style: AppTypography.bodyMdM.copyWith(
                  color: AppColors.foregroundTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 일치 키워드 없을 때 안내 카드
class ExerciseNoResult extends StatelessWidget {
  const ExerciseNoResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('exercise-no-result'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing4,
        vertical: AppSpacing.spacing1 + AppSpacing.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '해당 운동을 찾지 못했어요',
            style: AppTypography.bodyMdM.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing05),
          Text(
            '다른 키워드로 검색하거나 유사 운동을 선택해주세요',
            style: AppTypography.bodySmR.copyWith(
              color: AppColors.foregroundTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
