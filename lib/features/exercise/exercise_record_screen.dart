import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/exercise/exercise_add_screen.dart';
import 'package:glucomi/features/exercise/exercise_models.dart';
import 'package:glucomi/features/exercise/widgets/exercise_fields.dart';
import 'package:glucomi/features/weight/widgets/weight_date_sheet.dart';
import 'package:glucomi/shared/widgets/app_confirm_dialog.dart';
import 'package:glucomi/shared/widgets/app_date_field.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// MO-EXERCISE-010 운동
///
/// - [record] 없음: (a) 기록없음 → 운동을 추가하면 (b) 기록있음 → 저장하기
/// - [record] 있음: (c) 등록후 → 삭제하기 / 수정하기 (수정하기 탭 시 (b) 로 전환)
///
/// 닫을 때 [ExerciseRecordResult] 를 돌려줌 (닫기·변경 없는 수정은 null)
class ExerciseRecordScreen extends StatefulWidget {
  const ExerciseRecordScreen({
    super.key,
    required this.repository,
    this.record,
    this.now,
  });

  final ExerciseRepository repository;

  /// 이미 저장된 기록으로 진입할 때
  final ExerciseRecord? record;

  /// 진입 시각 (테스트용으로 바꿀 수 있음)
  final DateTime? now;

  @override
  State<ExerciseRecordScreen> createState() => _ExerciseRecordScreenState();
}

class _ExerciseRecordScreenState extends State<ExerciseRecordScreen> {
  late bool _editing = widget.record == null;

  /// 날짜 + 시간 (진입 시 오늘 날짜 · 현재 시각, 수정 모드는 저장값 유지)
  late DateTime _time = widget.record?.time ?? (widget.now ?? DateTime.now());
  late final List<ExerciseEntry> _entries = [...?widget.record?.entries];
  late final TextEditingController _memo = TextEditingController(
    text: widget.record?.memo ?? '',
  );
  bool _busy = false;

  DateTime get _today {
    final t = widget.now ?? DateTime.now();
    return DateTime(t.year, t.month, t.day);
  }

  /// 운동 1건 이상 + 모든 운동 시간이 0분/빈 값이 아님
  bool get _canSave => _entries.isNotEmpty && _entries.every((e) => e.isValid);

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  /// 진입 직전 화면으로 복귀 (입력·변경이 있어도 확인 팝업 없이 바로 닫힘)
  void _close() => Navigator.of(context).maybePop();

  Future<void> _pickDate() async {
    final picked = await showWeightDateSheet(
      context,
      selected: _time,
      today: _today,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _time = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _time.hour,
        _time.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showExerciseTimeSheet(context, initial: _time);
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  Future<void> _addExercise() async {
    FocusScope.of(context).unfocus();
    final exercise = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(
        builder: (_) => ExerciseAddScreen(repository: widget.repository),
      ),
    );
    if (exercise == null || !mounted) return;
    setState(() {
      _entries.add(
        ExerciseEntry(
          exercise: exercise,
          minutes: ExercisePolicy.defaultMinutes,
        ),
      );
    });
  }

  Future<void> _save() async {
    if (!_canSave || _busy) return;
    final record = ExerciseRecord(
      id: widget.record?.id,
      time: _time,
      entries: _entries,
      memo: _memo.text,
    );

    // 수정: 변경 없음 → 저장 호출 없이 홈 화면 복귀
    final original = widget.record;
    if (original != null && original.sameContentAs(record)) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _busy = true);
    try {
      final saved = await widget.repository.save(record);
      if (mounted) {
        Navigator.of(context).pop(ExerciseRecordResult.saved(saved));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final id = widget.record?.id;
    if (id == null || _busy) return;
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.repository.delete(id);
      if (mounted) {
        Navigator.of(context).pop(const ExerciseRecordResult.deleted());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editable = _editing && !_busy;
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '운동',
              iconLeft: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  key: const ValueKey('exercise-close'),
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
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.spacing4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppDateField(
                              key: const ValueKey('exercise-date'),
                              date: _time,
                              isRequired: true,
                              onTap: editable ? _pickDate : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spacing3),
                          Expanded(
                            child: ExerciseTimeField(
                              key: const ValueKey('exercise-time'),
                              time: _time,
                              onTap: editable ? _pickTime : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spacing6),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: ExerciseFieldLabel('운동 선택', isRequired: true),
                      ),
                      const SizedBox(height: AppSpacing.spacing3),
                      ..._buildEntries(editable),
                      const SizedBox(height: AppSpacing.spacing6),
                      ExerciseMemoField(controller: _memo, enabled: editable),
                    ],
                  ),
                ),
              ),
            ),
            if (_editing)
              BottomActionBar(
                key: const ValueKey('exercise-save'),
                label: '저장하기',
                onPressed: _canSave && !_busy ? _save : null,
              )
            else
              BottomActionBar(
                key: const ValueKey('exercise-registered-actions'),
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

  /// 운동 항목 목록 + 운동 추가하기 (정책상 여러 건 기록 가능 — 수정 가능할 때만 추가 버튼 노출)
  List<Widget> _buildEntries(bool editable) {
    return [
      for (var i = 0; i < _entries.length; i++) ...[
        if (i > 0) const SizedBox(height: AppSpacing.spacing2),
        ExerciseEntryTile(
          key: ValueKey('exercise-entry-$i-${_entries[i].exercise.id}'),
          entry: _entries[i],
          enabled: editable,
          // 시간 변경 시 소모 칼로리 실시간 재계산
          onMinutesChanged: (m) =>
              setState(() => _entries[i] = _entries[i].copyWith(minutes: m)),
          // 전체 삭제 시 (a) 상태로 복귀 → 저장하기 비활성
          onRemove: () => setState(() => _entries.removeAt(i)),
        ),
      ],
      if (_editing) ...[
        if (_entries.isNotEmpty) const SizedBox(height: AppSpacing.spacing2),
        ExerciseAddButton(onTap: editable ? _addExercise : null),
      ],
    ];
  }
}
