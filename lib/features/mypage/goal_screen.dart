import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/widgets/range_wheel_picker.dart';
import 'package:glucomi/features/mypage/mypage_models.dart';
import 'package:glucomi/shared/widgets/app_bottom_sheet_frame.dart';
import 'package:glucomi/shared/widgets/app_button.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';

/// 목표 혈당 범위 (MO-CURATION-010 (d) 와 같게: 50~230, 스냅 1, 최소 간격 30)
abstract final class GoalRange {
  static const int lowest = 50;
  static const int highest = 230;
  static const int gap = 30;

  static final List<int> minValues = [
    for (var v = lowest; v <= highest - gap; v++) v,
  ];
  static final List<int> maxValues = [
    for (var v = lowest + gap; v <= highest; v++) v,
  ];
}

/// MO-GOAL-010 목표혈당범위 (내 목표 혈당)
class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key, required this.repository});

  final MyPageRepository repository;

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  int? get _min => widget.repository.data?.targetMin;
  int? get _max => widget.repository.data?.targetMax;

  Future<void> _edit() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<({int min, int max})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0xB3000000), // DIM: black 70%
      builder: (_) => _GoalRangeSheet(min: _min ?? 70, max: _max ?? 180),
    );
    if (result == null) return;
    await widget.repository.updateTarget(result.min, result.max);
    if (!mounted) return;
    setState(() {});
    showAppToastOn(messenger, '변경 완료되었습니다', type: AppToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final min = _min;
    final max = _max;
    final valueStyle = AppTypography.displaySm.copyWith(
      color: AppColors.foregroundPrimary,
    );

    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '내 목표 혈당',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.spacing4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '내 목표 혈당 관리',
                                  style: AppTypography.headingH3.copyWith(
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                key: const ValueKey('goal-edit'),
                                behavior: HitTestBehavior.opaque,
                                onTap: _edit,
                                child: Row(
                                  children: [
                                    Text(
                                      '수정하기',
                                      style: AppTypography.bodySmM.copyWith(
                                        color: AppColors.foregroundQuaternary,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.spacing1),
                                    SvgPicture.asset(
                                      'assets/mypage/pencil_edit_12.svg',
                                      width: 12,
                                      height: 12,
                                      excludeFromSemantics: true,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.spacing1),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.spacing4,
                              vertical: AppSpacing.spacing6,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('${min ?? '-'}', style: valueStyle),
                                const SizedBox(width: AppSpacing.spacing10),
                                Text('-', style: valueStyle),
                                const SizedBox(width: AppSpacing.spacing10),
                                Text('${max ?? '-'}', style: valueStyle),
                                const SizedBox(width: AppSpacing.spacing10),
                                Text(
                                  'mg/dL',
                                  style: AppTypography.headingH3.copyWith(
                                    color: AppColors.foregroundPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.spacing4),
                      child: _RecommendAlert(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 따당의 추천 구간 안내 (Figma Alert)
class _RecommendAlert extends StatelessWidget {
  const _RecommendAlert();

  @override
  Widget build(BuildContext context) {
    final bodyStyle = AppTypography.bodySmR.copyWith(
      color: AppColors.foregroundTertiary,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing4),
      decoration: BoxDecoration(
        color: AppColors.neutralsSubtle,
        borderRadius: BorderRadius.circular(AppRadius.radiusLg),
        border: Border.all(color: AppColors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SvgPicture.asset(
                'assets/curation/info.svg',
                width: 20,
                height: 20,
                excludeFromSemantics: true,
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '따당의 추천 구간은 '),
                      TextSpan(
                        text: '70-150 mg/dL',
                        style: AppTypography.bodyMdM.copyWith(
                          color: AppColors.accentsBrand,
                        ),
                      ),
                    ],
                  ),
                  style: AppTypography.bodyMdM.copyWith(
                    color: AppColors.foregroundPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing1),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 12, child: Text('•', style: bodyStyle)),
                Expanded(
                  child: Text(
                    '혈당 스파이크와 합병증 예방을 위해,\n권장 범위보다 더 좁은 목표를 추천해요.',
                    style: bodyStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// MO-GOAL-010 (b) 목표 범위 설정 바텀시트 (COM-POP-00)
class _GoalRangeSheet extends StatefulWidget {
  const _GoalRangeSheet({required this.min, required this.max});

  final int min;
  final int max;

  @override
  State<_GoalRangeSheet> createState() => _GoalRangeSheetState();
}

class _GoalRangeSheetState extends State<_GoalRangeSheet> {
  late int _min = widget.min.clamp(
    GoalRange.minValues.first,
    GoalRange.minValues.last,
  );
  late int _max = widget.max.clamp(
    GoalRange.maxValues.first,
    GoalRange.maxValues.last,
  );

  bool get _changed => _min != widget.min || _max != widget.max;

  @override
  Widget build(BuildContext context) {
    return AppBottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '목표 범위 설정',
            textAlign: TextAlign.center,
            style: AppTypography.headingH3.copyWith(
              color: AppColors.foregroundPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          RangeWheelPicker(
            minValues: GoalRange.minValues,
            maxValues: GoalRange.maxValues,
            minValue: _min,
            maxValue: _max,
            // 한쪽이 최소 간격을 넘어서면 반대쪽을 밀어냄
            onMinChanged: (v) => setState(() {
              _min = v;
              if (_max - v < GoalRange.gap) _max = v + GoalRange.gap;
            }),
            onMaxChanged: (v) => setState(() {
              _max = v;
              if (v - _min < GoalRange.gap) _min = v - GoalRange.gap;
            }),
          ),
          const SizedBox(height: AppSpacing.spacing4),
          AppButton(
            key: const ValueKey('goal-save'),
            label: '저장하기',
            onPressed: _changed
                ? () => Navigator.of(context).pop((min: _min, max: _max))
                : null,
          ),
        ],
      ),
    );
  }
}
