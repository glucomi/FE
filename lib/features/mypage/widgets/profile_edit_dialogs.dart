import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/curation_models.dart';
import 'package:glucomi/features/curation/widgets/diabetes_type_option.dart';
import 'package:glucomi/features/curation/widgets/ruler_picker.dart';
import 'package:glucomi/features/mypage/mypage_models.dart';
import 'package:glucomi/features/mypage/widgets/text_wheel_picker.dart';
import 'package:glucomi/shared/widgets/app_button.dart';

/// 이름 최대 글자 수 (정책서에 없어 임시로 10자)
const int profileNameMaxLength = 10;

/// 키 입력 범위 (MO-CURATION-010 과 같게)
const int profileHeightMin = 100;
const int profileHeightMax = 250;

Future<T?> _showEditDialog<T>(BuildContext context, Widget dialog) {
  return showDialog<T>(
    context: context,
    barrierColor: const Color(0xB3000000), // DIM: black 70%
    builder: (_) => dialog,
  );
}

Future<String?> showNameEditDialog(BuildContext context, String current) =>
    _showEditDialog(context, _NameEditDialog(initial: current));

Future<DateTime?> showBirthEditDialog(
  BuildContext context,
  DateTime? current,
) => _showEditDialog(context, _BirthEditDialog(initial: current));

Future<Gender?> showGenderEditDialog(BuildContext context, Gender? current) =>
    _showEditDialog(context, _GenderEditDialog(initial: current));

Future<int?> showHeightEditDialog(BuildContext context, int? current) =>
    _showEditDialog(context, _HeightEditDialog(initial: current));

Future<DiabetesType?> showDiabetesEditDialog(
  BuildContext context,
  DiabetesType? current,
) => _showEditDialog(context, _DiabetesEditDialog(initial: current));

/// MO-PROFILE-010 수정 팝업 공통 틀 (Dialog 320px, 제목 + 내용 + 취소/수정하기)
class ProfileEditDialog extends StatelessWidget {
  const ProfileEditDialog({
    super.key,
    required this.title,
    required this.child,
    required this.onSubmit,
  });

  final String title;
  final Widget child;

  /// null 이면 '수정하기' 비활성
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(AppSpacing.spacing4),
        decoration: BoxDecoration(
          color: AppColors.neutralsBackground,
          border: Border.all(color: AppColors.borderDefault),
          borderRadius: BorderRadius.circular(AppRadius.radiusXl),
          boxShadow: AppShadows.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.spacing2),
              child: Text(
                title,
                style: AppTypography.headingH3.copyWith(
                  color: AppColors.foregroundPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.spacing3),
            Flexible(child: child),
            const SizedBox(height: AppSpacing.spacing3),
            Row(
              children: [
                Expanded(
                  child: AppOutlineButton(
                    key: const ValueKey('profile-edit-cancel'),
                    label: '취소',
                    height: AppSpacing.controlHeightMd,
                    horizontalPadding: AppSpacing.spacing4,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: AppSpacing.spacing3),
                Expanded(
                  child: AppSmallButton(
                    key: const ValueKey('profile-edit-submit'),
                    label: '수정하기',
                    onPressed: onSubmit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Figma Button: Primary (40px) — 팝업 안 주 버튼
class AppSmallButton extends StatelessWidget {
  const AppSmallButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.controlHeightMd,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.interactiveBrandDefault,
          disabledBackgroundColor: AppColors.interactiveBrandDisabled,
          foregroundColor: AppColors.foregroundOnAccent,
          disabledForegroundColor: AppColors.foregroundOnAccent,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          textStyle: AppTypography.btnMd,
        ),
        child: Text(label),
      ),
    );
  }
}

// ── 이름 ─────────────────────────────────────────────

class _NameEditDialog extends StatefulWidget {
  const _NameEditDialog({required this.initial});

  final String initial;

  @override
  State<_NameEditDialog> createState() => _NameEditDialogState();
}

class _NameEditDialogState extends State<_NameEditDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _hasSpace => _controller.text.contains(RegExp(r'\s'));

  bool get _canSubmit {
    final text = _controller.text;
    return text.isNotEmpty && !_hasSpace && text != widget.initial;
  }

  void _submit() {
    if (_canSubmit) Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final error = _hasSpace ? '띄어쓰기를 포함하지 말아주세요' : null;

    return ProfileEditDialog(
      title: '이름 수정',
      onSubmit: _canSubmit ? _submit : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: AppSpacing.controlHeightXl,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.spacing4),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: AppColors.neutralsSurface,
              borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              border: Border.all(
                color: error != null
                    ? AppColors.accentsDanger
                    : AppColors.borderDefault,
                width: AppTokens.borderWidthDefault,
              ),
            ),
            child: TextField(
              key: const ValueKey('profile-name-field'),
              controller: _controller,
              autofocus: true,
              maxLength: profileNameMaxLength,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
              cursorColor: AppColors.accentsBrand,
              style: AppTypography.bodyMdR.copyWith(
                color: AppColors.foregroundPrimary,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                hintText: '이름을 입력해 주세요',
                hintStyle: AppTypography.bodyMdR.copyWith(
                  color: AppColors.foregroundQuaternary,
                ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.spacing2),
            Text(
              error,
              style: AppTypography.labelMeta.copyWith(
                color: AppColors.accentsDanger,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 생년월일 ─────────────────────────────────────────

class _BirthEditDialog extends StatefulWidget {
  const _BirthEditDialog({required this.initial});

  final DateTime? initial;

  @override
  State<_BirthEditDialog> createState() => _BirthEditDialogState();
}

class _BirthEditDialogState extends State<_BirthEditDialog> {
  static const int _firstYear = 1900;
  static final DateTime _today = DateTime.now();
  static final DateTime _fallback = DateTime(2000, 1, 1);

  late int _year = (widget.initial ?? _fallback).year;
  late int _month = (widget.initial ?? _fallback).month;
  late int _day = (widget.initial ?? _fallback).day;

  List<int> get _years => [for (var y = _firstYear; y <= _today.year; y++) y];

  List<int> get _months => [
    for (var m = 1; m <= (_year == _today.year ? _today.month : 12); m++) m,
  ];

  List<int> get _days {
    final last = DateUtils.getDaysInMonth(_year, _month);
    final limit = _year == _today.year && _month == _today.month
        ? _today.day
        : last;
    return [for (var d = 1; d <= limit; d++) d];
  }

  DateTime get _selected => DateTime(_year, _month, _day);

  bool get _changed {
    final initial = widget.initial;
    return initial == null || !DateUtils.isSameDay(initial, _selected);
  }

  /// 연·월이 바뀌어 고른 월/일이 범위를 넘으면 마지막 값으로 맞춤
  void _clamp() {
    final months = _months;
    if (_month > months.last) _month = months.last;
    final days = _days;
    if (_day > days.last) _day = days.last;
  }

  @override
  Widget build(BuildContext context) {
    return ProfileEditDialog(
      title: '생년월일 수정',
      onSubmit: _changed
          ? () => Navigator.of(context).pop(_selected)
          : null,
      child: TextWheelPicker(
        columns: [
          TextWheelColumn(
            key: const ValueKey('birth-year'),
            width: 92,
            values: _years,
            value: _year,
            label: (v) => '$v년',
            onChanged: (v) => setState(() {
              _year = v;
              _clamp();
            }),
          ),
          TextWheelColumn(
            key: const ValueKey('birth-month'),
            width: 56,
            values: _months,
            value: _month,
            label: (v) => '$v월',
            onChanged: (v) => setState(() {
              _month = v;
              _clamp();
            }),
          ),
          TextWheelColumn(
            key: const ValueKey('birth-day'),
            width: 56,
            values: _days,
            value: _day,
            label: (v) => '$v일',
            onChanged: (v) => setState(() => _day = v),
          ),
        ],
      ),
    );
  }
}

// ── 성별 ─────────────────────────────────────────────

class _GenderEditDialog extends StatefulWidget {
  const _GenderEditDialog({required this.initial});

  final Gender? initial;

  @override
  State<_GenderEditDialog> createState() => _GenderEditDialogState();
}

class _GenderEditDialogState extends State<_GenderEditDialog> {
  late Gender? _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return ProfileEditDialog(
      title: '성별 수정',
      onSubmit: selected != null && selected != widget.initial
          ? () => Navigator.of(context).pop(selected)
          : null,
      child: Row(
        children: [
          for (final gender in Gender.values) ...[
            if (gender != Gender.values.first)
              const SizedBox(width: AppSpacing.spacing2),
            Expanded(
              child: DiabetesTypeOption(
                key: ValueKey('gender-${gender.name}'),
                label: gender.optionLabel,
                selected: gender == selected,
                onTap: () => setState(() => _selected = gender),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── 키 ───────────────────────────────────────────────

class _HeightEditDialog extends StatefulWidget {
  const _HeightEditDialog({required this.initial});

  final int? initial;

  @override
  State<_HeightEditDialog> createState() => _HeightEditDialogState();
}

class _HeightEditDialogState extends State<_HeightEditDialog> {
  late int _height = (widget.initial ?? 160).clamp(
    profileHeightMin,
    profileHeightMax,
  );

  @override
  Widget build(BuildContext context) {
    return ProfileEditDialog(
      title: '키 수정',
      onSubmit: _height != widget.initial
          ? () => Navigator.of(context).pop(_height)
          : null,
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: RulerPicker.rulerThickness,
              child: RulerPicker(
                key: const ValueKey('profile-height-ruler'),
                axis: Axis.vertical,
                min: profileHeightMin.toDouble(),
                max: profileHeightMax.toDouble(),
                step: 1,
                value: _height.toDouble(),
                onChanged: (v) => setState(() => _height = v.round()),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 70,
              child: RulerFade(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 70,
              child: RulerFade(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
            const Align(
              alignment: Alignment.centerLeft,
              child: IgnorePointer(child: RulerIndicator(axis: Axis.vertical)),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 84),
                child: RulerValueLabel(value: '$_height', unit: 'cm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 당뇨 여부 ────────────────────────────────────────

class _DiabetesEditDialog extends StatefulWidget {
  const _DiabetesEditDialog({required this.initial});

  final DiabetesType? initial;

  @override
  State<_DiabetesEditDialog> createState() => _DiabetesEditDialogState();
}

class _DiabetesEditDialogState extends State<_DiabetesEditDialog> {
  late DiabetesType? _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return ProfileEditDialog(
      title: '당뇨 여부 수정',
      onSubmit: selected != null && selected != widget.initial
          ? () => Navigator.of(context).pop(selected)
          : null,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final type in DiabetesType.values) ...[
              if (type != DiabetesType.values.first)
                const SizedBox(height: AppSpacing.spacing2),
              DiabetesTypeOption(
                key: ValueKey('profile-diabetes-${type.name}'),
                label: type.label,
                selected: type == selected,
                onTap: () => setState(() => _selected = type),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
