import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/curation/widgets/ruler_picker.dart';
import 'package:glucomi/features/weight/weight_models.dart';
import 'package:glucomi/features/weight/widgets/weight_date_sheet.dart';
import 'package:glucomi/shared/widgets/app_confirm_dialog.dart';
import 'package:glucomi/shared/widgets/app_date_field.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// MO-WEIGHT-010 체중
///
/// - [record] 없음: (a) 기본 → 저장하기
/// - [record] 있음: (b) 등록후 → 삭제하기 / 수정하기 (수정하기 탭 시 (a) 로 전환)
///
/// 닫을 때 [WeightRecordResult] 를 돌려줌 (닫기·변경 없는 수정은 null)
class WeightRecordScreen extends StatefulWidget {
  const WeightRecordScreen({
    super.key,
    required this.repository,
    this.record,
    this.previousKg,
    this.today,
  });

  final WeightRepository repository;

  /// 이미 저장된 기록으로 진입할 때
  final WeightRecord? record;

  /// 직전 저장값 (없으면 저장소의 최근 기록 → 그것도 없으면 기본 시작값)
  final double? previousKg;

  /// 오늘 날짜 (테스트용으로 바꿀 수 있음)
  final DateTime? today;

  @override
  State<WeightRecordScreen> createState() => _WeightRecordScreenState();
}

class _WeightRecordScreenState extends State<WeightRecordScreen> {
  late bool _editing = widget.record == null;
  late DateTime _date = widget.record?.date ?? _today;
  double? _kg;
  bool _busy = false;

  DateTime get _today {
    final t = widget.today ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    if (record != null) {
      _kg = record.kg;
    } else if (widget.previousKg != null) {
      _kg = WeightPolicy.normalize(widget.previousKg!);
    } else {
      _loadStartValue();
    }
  }

  /// 직전 저장값이 있으면 해당 값으로, 없으면 기본 시작값으로 진입
  Future<void> _loadStartValue() async {
    final last = await widget.repository.latest();
    if (!mounted) return;
    setState(() => _kg = last?.kg ?? WeightPolicy.defaultStartKg);
  }

  /// 진입 직전 화면으로 복귀 (입력·변경이 있어도 확인 팝업 없이 바로 닫힘)
  void _close() => Navigator.of(context).maybePop();

  Future<void> _pickDate() async {
    final picked = await showWeightDateSheet(
      context,
      selected: _date,
      today: _today,
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _save() async {
    final kg = _kg;
    if (kg == null || _busy) return;
    final record = WeightRecord(date: _date, kg: kg);

    // 수정: 수치 변화 없음(기존값=현재값) → 저장 호출 없이 홈 화면 복귀
    if (widget.record != null && widget.record == record) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _busy = true);
    try {
      // 동일 일자에 기존 기록이 있으면 최신값으로 갱신 (저장소에서 처리)
      await widget.repository.save(record);
      if (mounted) Navigator.of(context).pop(WeightRecordResult.saved(record));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final record = widget.record;
    if (record == null || _busy) return;
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.repository.delete(record.date);
      if (mounted) {
        Navigator.of(context).pop(const WeightRecordResult.deleted());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '체중',
              iconLeft: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  key: const ValueKey('weight-close'),
                  onTap: _busy ? null : _close,
                  behavior: HitTestBehavior.opaque,
                  child: SvgPicture.asset(
                    'assets/weight/close.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.spacing4),
              decoration: const BoxDecoration(
                color: AppColors.neutralsBackground,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderDefault),
                ),
              ),
              child: AppDateField(
                key: const ValueKey('weight-date'),
                date: _date,
                onTap: _editing && !_busy ? _pickDate : null,
              ),
            ),
            Expanded(child: _kg == null ? const SizedBox.shrink() : _buildRuler()),
            if (_editing)
              BottomActionBar(
                key: const ValueKey('weight-save'),
                label: '저장하기',
                onPressed: _kg == null || _busy ? null : _save,
              )
            else
              BottomActionBar(
                key: const ValueKey('weight-registered-actions'),
                secondaryLabel: '삭제하기',
                onSecondaryPressed: _busy ? null : _delete,
                label: '수정하기',
                onPressed: _busy ? null : () => setState(() => _editing = true),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuler() {
    final kg = _kg!;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Figma: 콘텐츠 영역 위에서 119
          const SizedBox(height: 119),
          RulerValueLabel(value: kg.toStringAsFixed(1), unit: 'kg'),
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
                  child: IgnorePointer(
                    ignoring: !_editing || _busy,
                    child: RulerPicker(
                      key: const ValueKey('weight-ruler'),
                      axis: Axis.horizontal,
                      min: WeightPolicy.minKg,
                      max: WeightPolicy.maxKg,
                      step: WeightPolicy.stepKg,
                      value: kg,
                      onChanged: (v) =>
                          setState(() => _kg = WeightPolicy.normalize(v)),
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
    );
  }
}
