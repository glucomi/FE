import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/drug/drug_models.dart';
import 'package:glucomi/features/drug/drug_register_screen.dart';
import 'package:glucomi/features/drug/my_drugs_screen.dart';
import 'package:glucomi/features/weight/widgets/weight_date_sheet.dart';
import 'package:glucomi/shared/widgets/app_confirm_dialog.dart';
import 'package:glucomi/shared/widgets/app_date_field.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';
import 'package:glucomi/shared/widgets/record/record_field_label.dart';
import 'package:glucomi/shared/widgets/record/record_memo_field.dart';
import 'package:glucomi/shared/widgets/record/record_select_field.dart';
import 'package:glucomi/shared/widgets/record/record_sheets.dart';
import 'package:glucomi/shared/widgets/record/record_text_input.dart';
import 'package:glucomi/shared/widgets/record/record_time_field.dart';
import 'package:glucomi/shared/widgets/record/record_time_sheet.dart';

/// MO-DRUG-010 복약-진입
///
/// - [record] 없음: (a) 기본 → 복용약 선택(COM-POP-07) → (d) 기록있음 → 저장하기
/// - [record] 있음: (e) 등록후 → 삭제하기 / 수정하기 (수정하기 탭 시 (d) 로 전환)
///
/// 닫을 때 [DrugRecordResult] 를 돌려줌 (닫기·변경 없는 수정은 null)
class DrugRecordScreen extends StatefulWidget {
  const DrugRecordScreen({
    super.key,
    required this.repository,
    this.record,
    this.now,
  });

  final DrugRepository repository;

  /// 이미 저장된 기록으로 진입할 때
  final DrugRecord? record;

  /// 진입 시각 (테스트용으로 바꿀 수 있음)
  final DateTime? now;

  @override
  State<DrugRecordScreen> createState() => _DrugRecordScreenState();
}

class _DrugRecordScreenState extends State<DrugRecordScreen> {
  late final DateTime _now = widget.now ?? DateTime.now();

  late bool _editing = widget.record == null;

  // 진입 시 오늘 날짜·현재 시간. 저장된 기록은 저장된 값 그대로 (수정 모드에서도 유지)
  late DateTime _date = _dayOf(widget.record?.time ?? _now);
  late TimeOfDay _time = TimeOfDay.fromDateTime(widget.record?.time ?? _now);
  late DrugType? _type = widget.record?.type;
  late String? _memberMedicationId = widget.record?.memberMedicationId;
  late final _productController = TextEditingController(
    text: widget.record?.productName ?? '',
  );
  late final _memoController = TextEditingController(
    text: widget.record?.memo ?? '',
  );
  bool _busy = false;

  static DateTime _dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

  bool get _canEdit => _editing && !_busy;

  @override
  void dispose() {
    _productController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  /// 진입 직전 화면으로 복귀 (입력·변경이 있어도 확인 팝업 없이 바로 닫힘,
  /// 수정 중이던 변경분은 버리고 마지막 저장본 유지)
  void _close() => Navigator.of(context).maybePop();

  Future<void> _pickDate() async {
    final picked = await showWeightDateSheet(
      context,
      selected: _date,
      today: _dayOf(_now),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showRecordTimeSheet(context, selected: _time);
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  /// 약 종류 선택 → COM-POP-07. 새 복용약을 등록하고 오면 시트를 다시 띄움
  Future<void> _pickDrug({String? preselectId}) async {
    final List<SavedDrug> drugs;
    try {
      drugs = await widget.repository.savedDrugs();
    } catch (e) {
      _showError(e, '내 복용약을 불러오지 못했어요.');
      return;
    }
    if (!mounted) return;
    final preselect = preselectId == null
        ? null
        : drugs.indexWhere((d) => d.id == preselectId);
    final result = await showSavedItemSheet(
      context,
      title: '복용약 선택',
      addLabel: '새 복용약',
      countLabel: '저장된 복용약',
      emptyTitle: '저장된 복용약이 없습니다',
      emptyMessage: '새 복용약을 추가해주세요',
      items: [
        for (final d in drugs)
          SavedItemOption(title: d.type.label, subtitle: d.productName),
      ],
      selected: preselect == null || preselect < 0 ? null : preselect,
      // 정책: {약 종류}(좌) · {제품명}(우) 한 줄 구성
      subtitleAtEnd: true,
    );
    if (result == null || !mounted) return;

    if (result.addRequested) {
      final added = await _openRegister();
      if (added != null && mounted) await _pickDrug(preselectId: added.id);
      return;
    }
    final drug = drugs[result.index!];
    setState(() {
      _type = drug.type;
      _memberMedicationId = drug.id;
      _productController.text = drug.productName ?? '';
    });
  }

  Future<SavedDrug?> _openRegister() => Navigator.of(context).push<SavedDrug>(
    MaterialPageRoute(
      builder: (_) => DrugRegisterScreen(repository: widget.repository),
    ),
  );

  void _openMyDrugs() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MyDrugsScreen(repository: widget.repository),
      ),
    );
  }

  DrugRecord? _buildRecord() {
    final type = _type;
    if (type == null) return null;
    String? clean(String text) {
      final t = text.trim();
      return t.isEmpty ? null : t;
    }

    return DrugRecord(
      id: widget.record?.id,
      time: DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      ),
      type: type,
      memberMedicationId: _memberMedicationId,
      productName: clean(_productController.text),
      memo: clean(_memoController.text),
    );
  }

  Future<void> _save() async {
    final record = _buildRecord();
    if (record == null || _busy) return;

    // 수정했는데 바뀐 값이 없으면 저장 호출 없이 복귀
    if (widget.record != null && widget.record == record) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _busy = true);
    try {
      final saved = await widget.repository.saveRecord(record);
      if (mounted) Navigator.of(context).pop(DrugRecordResult.saved(saved));
    } catch (e) {
      _showError(e, '복약 기록을 저장하지 못했어요.');
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
      if (mounted) Navigator.of(context).pop(const DrugRecordResult.deleted());
    } catch (e) {
      _showError(e, '복약 기록을 삭제하지 못했어요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(Object error, String fallback) {
    if (!mounted) return;
    showAppToast(
      context,
      error is ApiException ? error.message : fallback,
      type: AppToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '복용약',
              iconLeft: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  key: const ValueKey('drug-close'),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.spacing4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppDateField(
                            key: const ValueKey('drug-date'),
                            date: _date,
                            onTap: _canEdit ? _pickDate : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spacing3),
                        Expanded(
                          child: RecordTimeField(
                            key: const ValueKey('drug-time'),
                            time: _time,
                            onTap: _canEdit ? _pickTime : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing6),
                    _buildDrugSection(),
                    const SizedBox(height: AppSpacing.spacing6),
                    RecordMemoField(
                      fieldKey: const ValueKey('drug-memo'),
                      controller: _memoController,
                      hintText: '복용과 관련한 내용을 메모해보세요.',
                      maxLength: DrugPolicy.memoMaxLength,
                      enabled: _canEdit,
                    ),
                  ],
                ),
              ),
            ),
            if (_editing)
              BottomActionBar(
                key: const ValueKey('drug-save'),
                label: '저장하기',
                onPressed: _type == null || _busy ? null : _save,
              )
            else
              BottomActionBar(
                key: const ValueKey('drug-registered-actions'),
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

  Widget _buildDrugSection() {
    final type = _type;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecordFieldLabel(
          label: '복용약 선택',
          required: true,
          trailing: RecordChipButton(
            key: const ValueKey('drug-my-drugs'),
            label: '내 복용약',
            onTap: _busy ? null : _openMyDrugs,
          ),
        ),
        const SizedBox(height: AppSpacing.spacing2),
        RecordSelectField(
          key: const ValueKey('drug-select'),
          placeholder: '약 종류를 선택해주세요',
          value: type?.label,
          onTap: _canEdit ? _pickDrug : null,
        ),
        if (type != null) ...[
          const SizedBox(height: AppSpacing.spacing2),
          RecordTextInput(
            fieldKey: const ValueKey('drug-product'),
            controller: _productController,
            hintText: '제품명을 입력해주세요(선택)',
            maxLength: DrugPolicy.productNameMaxLength,
            enabled: _canEdit,
          ),
        ],
      ],
    );
  }
}
