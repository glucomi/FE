import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_checkbox.dart';

class SignupAllConsentCard extends StatefulWidget {
  const SignupAllConsentCard({
    super.key,
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  State<SignupAllConsentCard> createState() => _SignupAllConsentCardState();
}

class _SignupAllConsentCardState extends State<SignupAllConsentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '전체 동의',
      checked: widget.checked,
      enabled: widget.enabled,
      child: InkWell(
        onHover: (value) => setState(() => _hovered = value),
        key: const ValueKey('consent-all'),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.radiusXl),
        onTap: widget.enabled ? () => widget.onChanged(!widget.checked) : null,
        child: Container(
          height: 57,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing5,
            vertical: AppSpacing.spacing4,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            borderRadius: BorderRadius.circular(AppRadius.radiusXl),
            border: Border.all(
              color: AppColors.borderDefault,
              width: AppTokens.borderWidthDefault,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: AppCheckbox(
                  value: widget.checked,
                  hovered: _hovered,
                  size: AppCheckboxSize.md,
                  onChanged: widget.enabled ? widget.onChanged : null,
                ),
              ),
              const SizedBox(width: AppSpacing.spacing2),
              ExcludeSemantics(
                child: Text(
                  '전체 동의',
                  style: AppTypography.headingH3.copyWith(
                    color: AppColors.foregroundPrimary,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
