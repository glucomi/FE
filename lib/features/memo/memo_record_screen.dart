import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/camera/food_camera_screen.dart';
import 'package:glucomi/features/memo/memo_models.dart';
import 'package:glucomi/features/memo/widgets/memo_photo_section.dart';
import 'package:glucomi/features/memo/widgets/memo_text_field.dart';
import 'package:glucomi/features/memo/widgets/memo_time_field.dart';
import 'package:glucomi/features/memo/widgets/memo_time_sheet.dart';
import 'package:glucomi/features/weight/widgets/weight_date_sheet.dart';
import 'package:glucomi/shared/widgets/app_confirm_dialog.dart';
import 'package:glucomi/shared/widgets/app_date_field.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// 사진 한 장을 받아옴 (취소하면 null)
typedef MemoPhotoPicker = Future<MemoPhoto?> Function(BuildContext context);

/// 사진 추가하기 → MO-CAMERA-010 (촬영·앨범 선택한 사진을 그대로 돌려받음)
Future<MemoPhoto?> pickMemoPhotoWithCamera(BuildContext context) async {
  final file = await Navigator.of(context).push<XFile>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const FoodCameraScreen(analyze: false),
    ),
  );
  if (file == null) return null;
  return MemoPhoto(await file.readAsBytes(), name: file.name);
}

/// MO-MEMO-010 메모
///
/// - [record] 없음: (a) 기본-기록없음 → 입력 후 (b) 기본-기록있음 → 저장하기
/// - [record] 있음: (c) 등록후 → 삭제하기 / 수정하기 (수정하기 탭 시 (b) 로 전환)
///
/// 닫을 때 [MemoRecordResult] 를 돌려줌 (닫기·변경 없는 수정은 null)
class MemoRecordScreen extends StatefulWidget {
  const MemoRecordScreen({
    super.key,
    required this.repository,
    this.record,
    this.now,
    this.pickPhoto = pickMemoPhotoWithCamera,
  });

  final MemoRepository repository;

  /// 이미 저장된 기록으로 진입할 때
  final MemoRecord? record;

  /// 진입 시 기본 날짜·시간 (테스트용으로 바꿀 수 있음)
  final DateTime? now;

  final MemoPhotoPicker pickPhoto;

  @override
  State<MemoRecordScreen> createState() => _MemoRecordScreenState();
}

class _MemoRecordScreenState extends State<MemoRecordScreen> {
  late bool _editing = widget.record == null;
  late final DateTime _now = widget.now ?? DateTime.now();

  /// 진입 시 날짜는 오늘, 시간은 현재 시각
  /// (수정 모드에서도 저장된 시간을 그대로 유지)
  late DateTime _date = _dateOf(widget.record?.time ?? _now);
  late TimeOfDay _time = TimeOfDay.fromDateTime(widget.record?.time ?? _now);
  late final TextEditingController _text = TextEditingController(
    text: widget.record?.text ?? '',
  );
  late List<MemoPhoto> _photos = [...?widget.record?.photos];
  bool _busy = false;

  static DateTime _dateOf(DateTime t) => DateTime(t.year, t.month, t.day);

  bool get _canEdit => _editing && !_busy;

  @override
  void initState() {
    super.initState();
    // 저장하기 활성화 여부를 글자 입력에 맞춰 갱신
    _text.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _text
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  bool get _canSave => MemoPolicy.canSave(
    text: _text.text,
    photoCount: _photos.length,
  );

  /// 진입 직전 화면으로 복귀 (입력·변경이 있어도 확인 팝업 없이 바로 닫힘)
  void _close() => Navigator.of(context).maybePop();

  Future<void> _pickDate() async {
    final picked = await showWeightDateSheet(
      context,
      selected: _date,
      today: _dateOf(_now),
    );
    if (picked == null || !mounted) return;
    setState(() => _date = _dateOf(picked));
  }

  Future<void> _pickTime() async {
    final picked = await showMemoTimeSheet(context, selected: _time);
    if (picked == null || !mounted) return;
    setState(() => _time = picked);
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= MemoPolicy.maxPhotos) {
      _showMessage('사진은 최대 ${MemoPolicy.maxPhotos}장까지 추가할 수 있어요.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      final photo = await widget.pickPhoto(context);
      if (photo == null || !mounted) return;
      setState(() => _photos = [..._photos, photo]);
    } catch (_) {
      _showMessage('사진을 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _removePhoto(int index) {
    if (index < 0 || index >= _photos.length) return;
    setState(() => _photos = [..._photos]..removeAt(index));
  }

  Future<void> _save() async {
    if (!_canSave || _busy) return;
    final previous = widget.record;
    final record = MemoRecord(
      id: previous?.id,
      time: DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      ),
      text: _text.text.trim(),
      photos: _photos,
    );

    // 수정: 바뀐 내용이 없으면 저장 호출 없이 바로 복귀
    if (previous != null && previous.sameContentAs(record)) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _busy = true);
    try {
      final saved = await widget.repository.save(record);
      if (mounted) Navigator.of(context).pop(MemoRecordResult.saved(saved));
    } catch (e) {
      _showMessage(e is ApiException ? e.message : '메모를 저장하지 못했어요.');
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
      if (mounted) Navigator.of(context).pop(const MemoRecordResult.deleted());
    } catch (e) {
      _showMessage(e is ApiException ? e.message : '메모를 삭제하지 못했어요.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '메모',
              iconLeft: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  key: const ValueKey('memo-close'),
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
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.spacing4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppDateField(
                            key: const ValueKey('memo-date'),
                            date: _date,
                            onTap: _canEdit ? _pickDate : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spacing3),
                        Expanded(
                          child: MemoTimeField(
                            key: const ValueKey('memo-time'),
                            time: _time,
                            onTap: _canEdit ? _pickTime : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing6),
                    MemoPhotoSection(
                      photos: _photos,
                      onAdd: _canEdit ? _addPhoto : null,
                      onRemove: _canEdit ? _removePhoto : null,
                    ),
                    const SizedBox(height: AppSpacing.spacing6),
                    MemoTextField(
                      controller: _text,
                      maxLength: MemoPolicy.maxLength,
                      readOnly: !_editing,
                    ),
                  ],
                ),
              ),
            ),
            if (_editing)
              BottomActionBar(
                key: const ValueKey('memo-save'),
                label: '저장하기',
                onPressed: _canSave && !_busy ? _save : null,
              )
            else
              BottomActionBar(
                key: const ValueKey('memo-registered-actions'),
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
