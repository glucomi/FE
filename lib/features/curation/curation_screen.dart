import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/curation_models.dart';
import 'package:glucomi/features/curation/widgets/curation_step_header.dart';
import 'package:glucomi/features/curation/widgets/diabetes_type_option.dart';
import 'package:glucomi/features/curation/widgets/guideline_alert.dart';
import 'package:glucomi/features/curation/widgets/range_wheel_picker.dart';
import 'package:glucomi/features/curation/widgets/ruler_picker.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// MO-CURATION-010 큐레이션 (당뇨 유형 → 키 → 몸무게 → 목표 혈당 범위)
class CurationScreen extends StatefulWidget {
  const CurationScreen({super.key, this.onComplete, this.onExit});

  final Future<void> Function(CurationResult result)? onComplete;

  /// 1단계에서 뒤로가기를 눌렀을 때 (없으면 헤더에 뒤로가기 버튼을 숨김)
  final VoidCallback? onExit;

  @override
  State<CurationScreen> createState() => _CurationScreenState();
}

class _CurationScreenState extends State<CurationScreen> {
  static const _totalSteps = 4;
  // MO-CURATION-010 (d): 스냅 단위 1 mg/dL
  static final _minTargetValues = [for (var v = 40; v <= 130; v++) v];
  static final _maxTargetValues = [for (var v = 120; v <= 250; v++) v];

  int _step = 1;
  DiabetesType? _type;
  int _heightCm = 165;
  double _weightKg = 60;
  int _targetMin = 70;
  int _targetMax = 180;
  bool _targetTouched = false;
  bool _submitting = false;

  bool get _canProceed => switch (_step) {
    1 => _type != null,
    4 => _targetMin < _targetMax,
    _ => true,
  };

  void _back() {
    if (_submitting) return;
    if (_step == 1) {
      widget.onExit?.call();
      return;
    }
    setState(() => _step--);
  }

  Future<void> _next() async {
    if (!_canProceed || _submitting) return;

    if (_step == 1 && !_targetTouched) {
      final range = _type!.defaultTargetRange;
      _targetMin = range.min;
      _targetMax = range.max;
    }

    if (_step < _totalSteps) {
      setState(() => _step++);
      return;
    }

    final result = CurationResult(
      diabetesType: _type!,
      heightCm: _heightCm,
      weightKg: _weightKg,
      targetMin: _targetMin,
      targetMax: _targetMax,
    );

    if (widget.onComplete == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('큐레이션 저장 서비스 연결 준비 중입니다.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.onComplete!(result);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showBack = _step > 1 || widget.onExit != null;

    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(onBack: showBack ? _back : null),
            Expanded(
              child: KeyedSubtree(
                key: ValueKey('curation-step-$_step'),
                child: _buildStep(),
              ),
            ),
            BottomActionBar(
              key: const ValueKey('curation-next'),
              label: _step == _totalSteps ? '완료' : '다음',
              onPressed: _canProceed && !_submitting ? _next : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      1 => _buildTypeStep(),
      2 => _buildHeightStep(),
      3 => _buildWeightStep(),
      _ => _buildTargetStep(),
    };
  }

  Widget _buildTypeStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CurationStepHeader(
            step: 1,
            totalSteps: _totalSteps,
            title: '당뇨 유형을 입력해주세요',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing5,
              vertical: AppSpacing.spacing4,
            ),
            child: Column(
              children: [
                for (final type in DiabetesType.values) ...[
                  if (type != DiabetesType.values.first)
                    const SizedBox(height: AppSpacing.spacing3),
                  DiabetesTypeOption(
                    key: ValueKey('diabetes-${type.name}'),
                    label: type.label,
                    selected: _type == type,
                    onTap: () => setState(() => _type = type),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeightStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CurationStepHeader(
          step: 2,
          totalSteps: _totalSteps,
          title: '키를 입력해주세요',
          description: '최대한 정확한 키와 몸무게를 알려주세요',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.spacing10,
              vertical: AppSpacing.spacing4,
            ),
            child: Center(
              child: SizedBox(
                height: 362,
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: RulerPicker.rulerThickness,
                      child: RulerPicker(
                        key: const ValueKey('height-ruler'),
                        axis: Axis.vertical,
                        min: 100,
                        max: 220,
                        step: 1,
                        value: _heightCm.toDouble(),
                        onChanged: (v) => setState(() => _heightCm = v.round()),
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      height: 98,
                      child: RulerFade(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    const Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 98,
                      child: RulerFade(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: IgnorePointer(
                        child: RulerIndicator(axis: Axis.vertical),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 97),
                        child: RulerValueLabel(
                          value: '$_heightCm',
                          unit: 'cm',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const CurationStepHeader(
          step: 3,
          totalSteps: _totalSteps,
          title: '몸무게를 입력해주세요',
          description: '최대한 정확한 키와 몸무게를 알려주세요',
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RulerValueLabel(
                  value: _weightKg.toStringAsFixed(1),
                  unit: 'kg',
                ),
                const SizedBox(height: 19),
                SizedBox(
                  height: RulerPicker.indicatorLength,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: RulerPicker.rulerThickness,
                        child: RulerPicker(
                          key: const ValueKey('weight-ruler'),
                          axis: Axis.horizontal,
                          min: 30,
                          max: 150,
                          step: 0.1,
                          value: _weightKg,
                          onChanged: (v) => setState(
                            () => _weightKg = double.parse(v.toStringAsFixed(1)),
                          ),
                        ),
                      ),
                      const Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: 98,
                        child: RulerFade(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      const Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 98,
                        child: RulerFade(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                        ),
                      ),
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: IgnorePointer(
                          child: RulerIndicator(axis: Axis.horizontal),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTargetStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CurationStepHeader(
            step: 4,
            totalSteps: _totalSteps,
            title: '목표 혈당 범위를 입력해주세요',
            description: '혈당 스파이크와 합병증 예방을 위해,\n권장 범위보다 더 좁은 목표를 추천해요',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.spacing4 + 24),
            child: RangeWheelPicker(
              minValues: _minTargetValues,
              maxValues: _maxTargetValues,
              minValue: _targetMin,
              maxValue: _targetMax,
              onMinChanged: (v) => setState(() {
                _targetTouched = true;
                _targetMin = v;
              }),
              onMaxChanged: (v) => setState(() {
                _targetTouched = true;
                _targetMax = v;
              }),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.spacing4),
            child: GuidelineAlert(),
          ),
        ],
      ),
    );
  }
}
