import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';

enum AppCheckboxSize { sm, md, lg }

enum AppCheckboxVariant { boxed, mark }

class AppCheckbox extends StatefulWidget {
  const AppCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = AppCheckboxSize.md,
    this.variant = AppCheckboxVariant.boxed,
    this.hovered = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final AppCheckboxSize size;
  final AppCheckboxVariant variant;
  final bool hovered;

  bool get enabled => onChanged != null;

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox> {
  bool _isHovered = false;
  bool _isFocused = false;

  double get _size {
    switch (widget.size) {
      case AppCheckboxSize.sm:
        return 16;
      case AppCheckboxSize.md:
        return 20;
      case AppCheckboxSize.lg:
        return 24;
    }
  }

  double get _radius {
    switch (widget.size) {
      case AppCheckboxSize.sm:
        return 5;
      case AppCheckboxSize.md:
        return 6;
      case AppCheckboxSize.lg:
        return 7;
    }
  }

  bool get _hovered => widget.enabled && (_isHovered || widget.hovered);

  bool get _markOnly => widget.variant == AppCheckboxVariant.mark;

  Color get _markColor => widget.value
      ? (_hovered ? AppColors.interactiveBrandHover : AppColors.accentsBrand)
      : (_hovered ? AppColors.accentsBrand : AppColors.borderStrong);

  Color get _borderColor {
    if (widget.value || _hovered) {
      return AppColors.accentsBrand;
    }

    return AppColors.borderStrong;
  }

  Color get _backgroundColor {
    if (widget.value) {
      return _hovered
          ? AppColors.interactiveBrandHover
          : AppColors.accentsBrand;
    }

    return AppColors.neutralsSurface;
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.enabled,
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onChanged?.call(!widget.value);
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) {
        setState(() {
          _isFocused = value;
        });
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled
              ? () => widget.onChanged?.call(!widget.value)
              : null,
          child: Opacity(
            opacity: widget.enabled ? 1 : 0.5,
            child: SizedBox(
              width: _size,
              height: _size,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _markOnly ? Colors.transparent : _backgroundColor,
                  borderRadius: BorderRadius.circular(_radius),
                  border: _markOnly
                      ? null
                      : Border.all(
                          color: _borderColor,
                          width: AppTokens.borderWidthMedium,
                        ),
                  boxShadow: widget.enabled && _isFocused
                      ? [
                          BoxShadow(
                            color: AppColors.accentsBrand.withValues(
                              alpha: 0.18,
                            ),
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: _markOnly
                    ? SvgPicture.asset(
                        'assets/signup/check_on.svg',
                        width: _size,
                        height: _size,
                        colorFilter: ColorFilter.mode(
                          _markColor,
                          BlendMode.srcIn,
                        ),
                        excludeFromSemantics: true,
                      )
                    : widget.value
                    ? SvgPicture.asset(
                        'assets/signup/check_mark_${widget.size.name}.svg',
                        width: _size,
                        height: _size,
                        excludeFromSemantics: true,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
