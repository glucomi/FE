import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/features/insulin/insulin_register_screen.dart';
import 'package:glucomi/features/insulin/my_insulin_screen.dart';
import 'package:glucomi/features/insulin/widgets/insulin_fields.dart';
import 'package:glucomi/features/insulin/widgets/insulin_select_sheet.dart';
import 'package:glucomi/features/weight/widgets/weight_date_sheet.dart';
import 'package:glucomi/shared/widgets/app_confirm_dialog.dart';
import 'package:glucomi/shared/widgets/app_date_field.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';
import 'package:glucomi/shared/widgets/record/record_field_label.dart';
import 'package:glucomi/shared/widgets/record/record_memo_field.dart';
import 'package:glucomi/shared/widgets/record/record_select_field.dart';
import 'package:glucomi/shared/widgets/record/record_time_field.dart';
import 'package:glucomi/shared/widgets/record/record_time_sheet.dart';

/// MO-INSULIN-010 인슐린
///
/// - [record] 없음: (a) 기본 → 인슐린 선택(COM-POP-06) → 투여량 → 저장하기
/// - [record] 있음: (f) 등록후 → 삭제하기 / 수정하기 (수정하기 탭 시 저장하기로 전환)
///
/// 닫을 때 [InsulinRecordResult] 를 돌려줌 (닫기·변경 없는 수정은 null)
class InsulinRecordScreen extends StatefulWidget {
  const InsulinRecordScreen({
    super.key,
    required this.repository,
    this.record,
    this.now,
  });

  final InsulinRepository repository;

  /// 이미 저장된 기록으로 진입할 때
  final InsulinRecord? record;

  /// 지금 시각 (테스트용으로 바꿀 수 있음). 날짜·시간 기본값에 씀
  final DateTime? now;

  @override
  State<InsulinRecordScreen> createState() => _InsulinRecordScreenState();
}

class _InsulinRecordScreenState extends State<InsulinRecordScreen> {
  late final DateTime _now = widget.now ?? DateTime.now();

  late bool _editing = widget.record == null;

  /// 진입 시 오늘 날짜 / 현재 시간 (수정 모드에서도 저장된 시간을 그대로 유지)
  late DateTime _date = _dateOnly(widget.record?.time ?? _now);
  late TimeOfDay _time = TimeOfDay.fromDateTime(widget.record?.time ?? _now);

  late InsulinProduct? _product = widget.record?.product;

  /// 바텀시트에서 고른 내 인슐린 (다시 열 때 선택 표시용)
  String? _myInsulinId;

  late final _doseController = TextEditingController(
    text: widget.record == null
        ? ''
        : InsulinDosePolicy.format(widget.record!.dose),
  );
  late final _memoController = TextEditingController(
    text: widget.record?.memo ?? '',
  );

  bool _busy = false;

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void initState() {
    super.initState();
    _doseController.addListener(_refresh);
  }

  @override
  void dispose() {
    _doseController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  double? get _dose => InsulinDosePolicy.parse(_doseController.text);

  /// 인슐린 선택 + 투여량 유효 입력 시 활성
  bool get _canSave => _product != null && _dose != null && !_busy;

  bool get _interactive => _editing && !_busy;

  /// 진입 직전 화면으로 복귀 (입력·변경이 있어도 확인 팝업 없이 바로 닫힘)
  void _close() => Navigator.of(context).maybePop();

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showWeightDateSheet(
      context,
      selected: _date,
      today: _dateOnly(_now),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = _dateOnly(picked));
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final picked = await showRecordTimeSheet(context, selected: _time);
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  /// COM-POP-06. 열 때마다 내 인슐린을 새로 불러옴 (030 에서 지우거나 추가한 내용 반영)
  Future<void> _openSelectSheet() async {
    FocusScope.of(context).unfocus();
    final insulins = await widget.repository.myInsulins();
    if (!mounted) return;
    final result = await showInsulinSelectSheet(
      context,
      insulins: insulins,
      // 등록후 기록을 수정할 때는 같은 제품의 내 인슐린에 선택 표시
      selectedId:
          _myInsulinId ??
          insulins.where((m) => m.product == _product).firstOrNull?.id,
    );
    if (result == null || !mounted) return;

    if (result.addNew) {
      // ⑧ 새 인슐린 추가 → MO-INSULIN-020
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => InsulinRegisterScreen(repository: widget.repository),
        ),
      );
      return;
    }

    final insulin = result.insulin!;
    setState(() {
      _myInsulinId = insulin.id;
      _product = insulin.product;
      // 내 인슐린의 투여량을 불러오고, 필드에서 다시 고칠 수 있음
      _doseController.text = InsulinDosePolicy.format(insulin.dose);
    });
  }

  /// ④ 내 인슐린 관리 → MO-INSULIN-030
  Future<void> _openMyInsulin() async {
    FocusScope.of(context).unfocus();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MyInsulinScreen(repository: widget.repository),
      ),
    );
  }

  Future<void> _save() async {
    final product = _product;
    final dose = _dose;
    if (product == null || dose == null || _busy) return;
    FocusScope.of(context).unfocus();

    final record = InsulinRecord(
      id: widget.record?.id,
      time: DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      ),
      product: product,
      dose: dose,
      memo: _memoController.text.trim(),
    );

    // 수정: 바뀐 내용 없음 → 저장 호출 없이 진입 화면(홈)으로 복귀
    if (widget.record != null && widget.record == record) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _busy = true);
    try {
      final saved = await widget.repository.saveRecord(record);
      if (mounted) {
        Navigator.of(context).pop(InsulinRecordResult.saved(saved));
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
      await widget.repository.deleteRecord(id);
      if (mounted) {
        Navigator.of(context).pop(const InsulinRecordResult.deleted());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '인슐린',
              iconLeft: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  key: const ValueKey('insulin-close'),
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
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.spacing4),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AppDateField(
                          key: const ValueKey('insulin-date'),
                          date: _date,
                          onTap: _interactive ? _pickDate : null,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.spacing3),
                      Expanded(
                        child: RecordTimeField(
                          key: const ValueKey('insulin-time'),
                          time: _time,
                          onTap: _interactive ? _pickTime : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing6),
                  RecordFieldLabel(
                    label: '인슐린 선택',
                    required: true,
                    trailing: RecordChipButton(
                      key: const ValueKey('insulin-my-list'),
                      label: '내 인슐린',
                      onTap: _busy ? null : _openMyInsulin,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing2),
                  RecordSelectField(
                    key: const ValueKey('insulin-select'),
                    value: product?.displayName,
                    placeholder: '저장한 인슐린을 선택해주세요',
                    onTap: _interactive ? _openSelectSheet : null,
                  ),
                  // ⑪ 투여량: 인슐린 선택 후 노출
                  if (product != null) ...[
                    const SizedBox(height: AppSpacing.spacing2),
                    InsulinDoseInput(
                      controller: _doseController,
                      readOnly: !_interactive,
                      fieldKey: const ValueKey('insulin-dose'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.spacing6),
                  RecordMemoField(
                    controller: _memoController,
                    fieldKey: const ValueKey('insulin-memo'),
                    hintText: '혈당과 관련한 내용을 메모해보세요.',
                    maxLength: InsulinRecordPolicy.memoMaxLength,
                    enabled: _interactive,
                  ),
                ],
              ),
            ),
            if (_editing)
              BottomActionBar(
                key: const ValueKey('insulin-save'),
                label: '저장하기',
                onPressed: _canSave ? _save : null,
              )
            else
              BottomActionBar(
                key: const ValueKey('insulin-registered-actions'),
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
}
