import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

/// Figma Switch (SM) — 36x20, 켜지면 브랜드 컬러
class AppSwitch extends StatelessWidget {
  const AppSwitch({super.key, required this.value, this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  static const Duration _duration = Duration(milliseconds: 150);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      child: MouseRegion(
        cursor: onChanged == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged == null ? null : () => onChanged!(!value),
          child: AnimatedContainer(
            duration: _duration,
            width: 36,
            height: 20,
            padding: const EdgeInsets.all(AppSpacing.spacing05),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              color: value ? AppColors.accentsBrand : AppColors.neutralsMuted,
              borderRadius: BorderRadius.circular(AppRadius.radiusFull),
            ),
            child: Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: AppShadows.defaultShadow,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
