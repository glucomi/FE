import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/shared/widgets/app_checkbox.dart';
import 'package:glucomi/shared/widgets/app_icons.dart';

class SignupConsentRow extends StatefulWidget {
  const SignupConsentRow({
    super.key,
    required this.index,
    required this.label,
    required this.checked,
    required this.enabled,
    required this.onChanged,
    this.onOpenDetail,
    this.reserveTrailingSpace = false,
  });

  final int index;
  final String label;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onOpenDetail;
  final bool reserveTrailingSpace;

  @override
  State<SignupConsentRow> createState() => _SignupConsentRowState();
}

class _SignupConsentRowState extends State<SignupConsentRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.label,
      checked: widget.checked,
      enabled: widget.enabled,
      child: InkWell(
        onHover: (value) => setState(() => _hovered = value),
        key: ValueKey('consent-${widget.index}'),
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: widget.enabled ? () => widget.onChanged(!widget.checked) : null,
        child: SizedBox(
          height: AppSpacing.controlHeightMd,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing4,
              vertical: AppSpacing.spacing2,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: AppCheckbox(
                    value: widget.checked,
                    hovered: _hovered,
                    size: AppCheckboxSize.lg,
                    variant: AppCheckboxVariant.mark,
                    onChanged: widget.enabled ? widget.onChanged : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing2),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: AppTypography.bodyMdR.copyWith(
                        color: AppColors.foregroundPrimary,
                        leadingDistribution: TextLeadingDistribution.even,
                      ),
                    ),
                  ),
                ),
                if (widget.onOpenDetail != null) ...[
                  const SizedBox(width: AppSpacing.spacing2),
                  GestureDetector(
                    key: ValueKey('term-${widget.index}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.enabled ? widget.onOpenDetail : null,
                    child: const SizedBox(
                      width: 16,
                      height: 16,
                      child: AppChevronRight(),
                    ),
                  ),
                ] else if (widget.reserveTrailingSpace) ...[
                  const SizedBox(width: AppSpacing.spacing2),
                  const SizedBox(width: 24, height: 24),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
