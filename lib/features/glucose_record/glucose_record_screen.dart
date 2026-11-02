import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/glucose_record/glucose_record_models.dart';
import 'package:glucomi/features/glucose_record/widgets/glucose_value_field.dart';
import 'package:glucomi/features/weight/widgets/weight_date_sheet.dart';
import 'package:glucomi/shared/widgets/app_confirm_dialog.dart';
import 'package:glucomi/shared/widgets/app_date_field.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_icons.dart';
import 'package:glucomi/shared/widgets/app_memo_field.dart';
import 'package:glucomi/shared/widgets/app_time_field.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// MO-GLUCOSER-010 혈당 (직접 기록)
///
/// - [record] 없음: (a) 기본-기록없음 → 저장하기
/// - [record] 있음: (c) 등록후 → 삭제하기 / 수정하기
///   수정하기 탭 시 (b) 기본-기록있음 으로 전환 → 저장하기
///
/// 닫을 때 [GlucoseRecordResult] 를 돌려줌 (닫기·변경 없는 수정은 null)
class GlucoseRecordScreen extends StatefulWidget {
  const GlucoseRecordScreen({
    super.key,
    required this.repository,
    this.record,
    this.today,
    this.now,
  });

  final GlucoseRecordRepository repository;

  /// 이미 저장된 기록으로 진입할 때
  final GlucoseRecord? record;

  /// 기본 날짜 (홈에서 보고 있는 날짜, 없으면 오늘)
  final DateTime? today;

  /// 새 기록의 기본 시각 (없으면 현재 시각)
  final DateTime? now;

  @override
  State<GlucoseRecordScreen> createState() => _GlucoseRecordScreenState();
}

class _GlucoseRecordScreenState extends State<GlucoseRecordScreen> {
  late final DateTime _now = widget.now ?? DateTime.now();
  late bool _editing = widget.record == null;
  late DateTime _date;
  late TimeOfDay _time;
  late final TextEditingController _valueController;
  late final TextEditingController _memoController;
  bool _busy = false;

  DateTime get _today {
    final t = widget.today ?? _now;
    return DateTime(t.year, t.month, t.day);
  }

  int? get _mgDl => int.tryParse(_valueController.text);

  bool get _canSave => GlucosePolicy.isValid(_mgDl) && !_busy;

  @override
  void initState() {
    super.initState();
    final record = widget.record;
    // 날짜: 진입 시 오늘 / 시간: 진입 시 현재 시각
    // 수정 모드에서도 저장된 날짜·시간을 그대로 유지 (현재 시각으로 갱신하지 않음)
    final time = record?.time;
    _date = time == null ? _today : DateTime(time.year, time.month, time.day);
    _time = TimeOfDay.fromDateTime(time ?? _now);
    _valueController = TextEditingController(
      text: record == null ? '' : '${record.mgDl}',
    )..addListener(_onValueChanged);
    _memoController = TextEditingController(text: record?.memo ?? '');
  }

  @override
  void dispose() {
    _valueController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _onValueChanged() => setState(() {});

  void _unfocus() => FocusScope.of(context).unfocus();

  /// 진입 직전 화면으로 복귀 (입력·변경이 있어도 확인 팝업 없이 바로 닫힘)
  void _close() => Navigator.of(context).maybePop();

  Future<void> _pickDate() async {
    _unfocus();
    final picked = await showWeightDateSheet(
      context,
      selected: _date,
      today: _today,
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    _unfocus();
    final picked = await showAppTimeSheet(context, selected: _time);
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  void _startEdit() => setState(() => _editing = true);

  Future<void> _save() async {
    final mgDl = _mgDl;
    if (!_canSave || mgDl == null) return;
    _unfocus();

    final existing = widget.record;
    final record = GlucoseRecord(
      id: existing?.id,
      time: DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      ),
      mgDl: mgDl,
      memo: _memoController.text.trim(),
    );

    // 수정: 변화 없음(기존값=현재값) → 저장 호출 없이 홈 화면 복귀
    if (existing != null && existing.sameContent(record)) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _busy = true);
    try {
      final saved = await widget.repository.save(record);
      if (mounted) Navigator.of(context).pop(GlucoseRecordResult.saved(saved));
    } catch (_) {
      if (mounted) _showMessage('저장하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final record = widget.record;
    if (record == null || _busy) return;
    _unfocus();
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      final id = record.id;
      if (id != null) await widget.repository.delete(id);
      if (mounted) {
        Navigator.of(context).pop(const GlucoseRecordResult.deleted());
      }
    } catch (_) {
      if (mounted) _showMessage('삭제하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
              title: '혈당',
              iconLeft: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  key: const ValueKey('glucose-close'),
                  onTap: _busy ? null : _close,
                  behavior: HitTestBehavior.opaque,
                  child: const SizedBox(
                    width: 24,
                    height: 24,
                    child: AppChevronLeft(),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: _unfocus,
                behavior: HitTestBehavior.opaque,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.spacing4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppDateField(
                              key: const ValueKey('glucose-date'),
                              date: _date,
                              onTap: editable ? _pickDate : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.spacing3),
                          Expanded(
                            child: AppTimeField(
                              key: const ValueKey('glucose-time'),
                              time: _time,
                              onTap: editable ? _pickTime : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.spacing6),
                      GlucoseValueField(
                        controller: _valueController,
                        readOnly: !editable,
                      ),
                      const SizedBox(height: AppSpacing.spacing6),
                      AppMemoField(
                        controller: _memoController,
                        hintText: '혈당과 관련한 내용을 메모해보세요.',
                        maxLength: GlucosePolicy.memoMaxLength,
                        readOnly: !editable,
                        fieldKey: const ValueKey('glucose-memo'),
                        counterKey: const ValueKey('glucose-memo-count'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_editing)
              BottomActionBar(
                key: const ValueKey('glucose-save'),
                label: '저장하기',
                onPressed: _canSave ? _save : null,
              )
            else
              BottomActionBar(
                key: const ValueKey('glucose-registered-actions'),
                secondaryLabel: '삭제하기',
                onSecondaryPressed: _busy ? null : _delete,
                label: '수정하기',
                onPressed: _busy ? null : _startEdit,
              ),
          ],
        ),
      ),
    );
  }
}
