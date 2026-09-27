import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

class CurationStepHeader extends StatelessWidget {
  const CurationStepHeader({
    super.key,
    required this.step,
    required this.totalSteps,
    required this.title,
    this.description,
  });

  final int step;
  final int totalSteps;
  final String title;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.spacing5,
        vertical: AppSpacing.spacing4,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing1),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'STEP ${step.toString().padLeft(2, '0')}',
                    style: AppTypography.bodySmM.copyWith(
                      color: AppColors.accentsBrand,
                    ),
                  ),
                ),
                for (var i = 1; i <= totalSteps; i++) ...[
                  if (i > 1) const SizedBox(width: AppSpacing.spacing2),
                  Container(
                    width: 24,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i == step
                          ? AppColors.accentsBrand
                          : AppColors.interactiveSecondaryDefault,
                      borderRadius: BorderRadius.circular(AppRadius.radiusFull),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.spacing2),
          Text(
            title,
            style: AppTypography.displaySm.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: AppSpacing.spacing2),
            Text(
              description!,
              style: AppTypography.bodyMdR.copyWith(
                color: AppColors.foregroundTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
