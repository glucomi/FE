import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/camera/food_camera_screen.dart';
import 'package:glucomi/features/meal/meal_detail_screen.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/widgets/meal_amount_field.dart';
import 'package:glucomi/features/meal/widgets/meal_form_widgets.dart';
import 'package:glucomi/features/meal/widgets/meal_photo_section.dart';
import 'package:glucomi/features/meal/widgets/meal_time_sheet.dart';
import 'package:glucomi/features/weight/widgets/weight_date_sheet.dart';
import 'package:glucomi/shared/widgets/app_date_field.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// 사진 한 장 고르기 (없으면 MO-CAMERA-010 으로 이동해서 찍거나 고름)
typedef MealPhotoPicker = Future<MealPhoto?> Function(BuildContext context);

/// MO-MEAL-040 음식 기록하기-저장
///
/// 저장하기를 누르면 서버에 저장한 뒤 [MealRecord] 를 돌려주며 닫힘.
/// 메뉴 수량·삭제는 [onEntriesChanged] 로 검색 화면(장바구니)과 맞춤
class MealSaveScreen extends StatefulWidget {
  const MealSaveScreen({
    super.key,
    required this.repository,
    required this.entries,
    this.onEntriesChanged,
    this.clock = DateTime.now,
    this.pickPhoto,
  });

  final MealFoodRepository repository;
  final List<MealEntry> entries;
  final ValueChanged<List<MealEntry>>? onEntriesChanged;
  final DateTime Function() clock;
  final MealPhotoPicker? pickPhoto;

  @override
  State<MealSaveScreen> createState() => _MealSaveScreenState();
}

class _MealSaveScreenState extends State<MealSaveScreen> {
  late final DateTime _now = widget.clock();

  // ① 진입 시 오늘 날짜, ② 현재 시간
  late DateTime _date = DateTime(_now.year, _now.month, _now.day);
  late TimeOfDay _time = TimeOfDay(hour: _now.hour, minute: _now.minute);

  late final List<MealEntry> _entries = [...widget.entries];
  final List<MealPhoto> _photos = [];
  final _memoController = TextEditingController();
  final Map<String, GlobalKey> _entryKeys = {};
  bool _saving = false;

  bool get _canSave =>
      !_saving &&
      _entries.isNotEmpty &&
      _entries.every((e) => e.amount >= MealPolicy.minAmount);

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _setEntries(void Function() change) {
    setState(change);
    widget.onEntriesChanged?.call(List.unmodifiable(_entries));
  }

  Future<void> _pickDate() async {
    final picked = await showWeightDateSheet(
      context,
      selected: _date,
      today: widget.clock(),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showMealTimeSheet(context, selected: _time);
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _addPhoto() async {
    // ⑪ 최대 10장, 초과 시 토스트
    if (_photos.length >= MealPolicy.photoMaxCount) {
      _showMessage(
        '사진은 최대 ${MealPolicy.photoMaxCount}장까지 등록할 수 있어요.',
        type: AppToastType.info, // COM-TOAST-03
      );
      return;
    }
    final photo = await (widget.pickPhoto ?? _openCamera)(context);
    if (photo == null || !mounted) return;
    setState(() => _photos.add(photo));
  }

  /// MO-CAMERA-010: 찍거나 고른 사진을 받아서 돌아옴
  static Future<MealPhoto?> _openCamera(BuildContext context) async {
    return Navigator.of(context).push<MealPhoto>(
      MaterialPageRoute(
        builder: (cameraContext) => FoodCameraScreen(
          onAnalyze: (file) async {
            final bytes = await file.readAsBytes();
            if (cameraContext.mounted) {
              Navigator.of(cameraContext).pop(MealPhoto(bytes: bytes));
            }
          },
        ),
      ),
    );
  }

  // ⑤ X 탭 시 해당 메뉴 삭제 (사진은 그대로)
  void _removeEntry(MealEntry entry) =>
      _setEntries(() => _entries.removeWhere((e) => e.food == entry.food));

  void _updateEntry(MealEntry entry) => _setEntries(() {
    final i = _entries.indexWhere((e) => e.food == entry.food);
    if (i >= 0) _entries[i] = entry;
  });

  // ④ 음식 상세(030) — 이 화면의 수량을 이어받고, 030 에서 바꾼 수량도 돌려받음
  Future<void> _openDetail(MealEntry entry) async {
    final updated = await Navigator.of(context).push<MealEntry>(
      MaterialPageRoute(
        builder: (_) => MealDetailScreen(
          repository: widget.repository,
          initial: entry,
        ),
      ),
    );
    if (updated != null && mounted) _updateEntry(updated);
  }

  // ⑩ 사진 위 음식칩 → 해당 음식 위치로 이동
  void _scrollToFood(String foodId) {
    final context = _entryKeys[foodId]?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 300),
      alignment: 0.1,
    );
  }

  Future<void> _save() async {
    if (!_canSave) return;
    final record = MealRecord(
      time: DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute),
      entries: List.unmodifiable(_entries),
      memo: _memoController.text,
      photos: List.unmodifiable(_photos),
    );
    setState(() => _saving = true);
    try {
      await widget.repository.saveRecord(record);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      final message = e is ApiException
          ? e.message
          : '식단을 기록하지 못했어요. 다시 시도해 주세요.';
      _showMessage(message);
      return;
    }
    if (mounted) Navigator.of(context).pop(record);
  }

  void _showMessage(String message, {AppToastType type = AppToastType.error}) {
    if (!mounted) return;
    showAppToast(context, message, type: type);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            // ⑫ 닫기: 저장하지 않으면 확인 없이 바로 이전 화면으로
            AppHeaderBar(
              title: '음식 기록하기',
              onBack: () => Navigator.of(context).maybePop(),
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
                        child: AppDateField(date: _date, onTap: _pickDate),
                      ),
                      const SizedBox(width: AppSpacing.spacing3),
                      Expanded(
                        child: _TimeField(time: _time, onTap: _pickTime),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.spacing6),
                  MealPhotoSection(
                    photos: _photos,
                    foodNames: {
                      for (final e in _entries) e.food.id: e.food.name,
                    },
                    onAdd: _addPhoto,
                    onRemove: (i) => setState(() => _photos.removeAt(i)),
                    onFoodTap: _scrollToFood,
                  ),
                  const SizedBox(height: AppSpacing.spacing6),
                  _buildMenus(),
                  const SizedBox(height: AppSpacing.spacing6),
                  _MemoField(controller: _memoController),
                ],
              ),
            ),
            BottomActionBar(
              label: '저장하기',
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MealFieldLabel(label: '식사 메뉴', required: true),
        const SizedBox(height: AppSpacing.spacing3),
        for (final entry in _entries) ...[
          _MenuCard(
            key: _entryKeys.putIfAbsent(entry.food.id, GlobalKey.new),
            entry: entry,
            onDetail: () => _openDetail(entry),
            onRemove: () => _removeEntry(entry),
            onChanged: _updateEntry,
          ),
          const SizedBox(height: AppSpacing.spacing3),
        ],
        // 메뉴를 더 담으러 검색 화면으로 (담은 메뉴는 그대로 유지)
        MealOutlineAddButton(
          key: const ValueKey('meal-save-add-menu'),
          label: '메뉴 추가하기',
          onTap: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

/// 2026년 04월 30일 옆 시간 선택 박스 (COM-03): 오후 02:03
class _TimeField extends StatelessWidget {
  const _TimeField({required this.time, required this.onTap});

  final TimeOfDay time;
  final VoidCallback onTap;

  static String format(TimeOfDay t) {
    final period = t.hour < 12 ? '오전' : '오후';
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    String two(int v) => v.toString().padLeft(2, '0');
    return '$period ${two(hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final text = format(time);
    return Semantics(
      button: true,
      label: '시간 $text',
      excludeSemantics: true,
      child: GestureDetector(
        key: const ValueKey('meal-save-time'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '시간',
              style: AppTypography.labelMeta.copyWith(
                color: AppColors.foregroundPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.spacing2),
            Container(
              height: AppSpacing.controlHeightLg,
              padding: const EdgeInsets.all(AppSpacing.spacing2),
              decoration: BoxDecoration(
                color: AppColors.neutralsBackground,
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(AppRadius.radiusSm),
              ),
              child: Row(
                children: [
                  SvgPicture.asset('assets/meal/time.svg', width: 24, height: 24),
                  const SizedBox(width: AppSpacing.spacing1),
                  Expanded(
                    child: Text(
                      text,
                      style: AppTypography.bodySmM.copyWith(
                        color: AppColors.foregroundPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 식사 메뉴 한 개: 분류·음식명(→ 상세) + 삭제 + 수량/단위
class _MenuCard extends StatelessWidget {
  const _MenuCard({
    super.key,
    required this.entry,
    required this.onDetail,
    required this.onRemove,
    required this.onChanged,
  });

  final MealEntry entry;
  final VoidCallback onDetail;
  final VoidCallback onRemove;
  final ValueChanged<MealEntry> onChanged;

  @override
  Widget build(BuildContext context) {
    final food = entry.food;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.spacing5),
      decoration: BoxDecoration(
        color: AppColors.neutralsBackground,
        border: Border.all(color: AppColors.borderDefault),
        borderRadius: BorderRadius.circular(AppRadius.radiusSm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Semantics(
                  button: true,
                  label: '${food.name} 상세 정보 보기',
                  child: GestureDetector(
                    key: ValueKey('meal-save-detail-${food.id}'),
                    onTap: onDetail,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      height: 46,
                      padding: const EdgeInsets.all(AppSpacing.spacing1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            food.labels.join(' · '),
                            style: AppTypography.labelBadge.copyWith(
                              color: AppColors.foregroundQuaternary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.spacing05),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  food.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.headingH3.copyWith(
                                    color: AppColors.foregroundPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.spacing15),
                              SvgPicture.asset(
                                'assets/meal/chevron_right_16.svg',
                                width: 16,
                                height: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.spacing2),
              Semantics(
                button: true,
                label: '${food.name} 삭제',
                child: GestureDetector(
                  key: ValueKey('meal-save-remove-${food.id}'),
                  onTap: onRemove,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.foregroundPrimary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(AppRadius.radiusSm),
                    ),
                    child: SvgPicture.asset(
                      'assets/meal/delete_16.svg',
                      width: 16,
                      height: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.spacing2 + 2),
          MealAmountField(
            entry: entry,
            keyPrefix: 'meal-save-${food.id}',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// 메모 (COM-04): 최대 1000자, 글자 수 실시간 표시
class _MemoField extends StatelessWidget {
  const _MemoField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.bodyMdR.copyWith(
      color: AppColors.foregroundPrimary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const MealFieldLabel(label: '메모'),
        const SizedBox(height: AppSpacing.spacing2),
        Container(
          constraints: const BoxConstraints(minHeight: 112),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
            vertical: AppSpacing.spacing3,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutralsBackground,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadius.radiusSm),
          ),
          child: TextField(
            key: const ValueKey('meal-save-memo'),
            controller: controller,
            minLines: 4,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            inputFormatters: [
              LengthLimitingTextInputFormatter(MealPolicy.memoMaxLength),
            ],
            style: style,
            cursorColor: AppColors.accentsBrand,
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: '식사량, 식사 순서 등을 메모해 보세요.',
              hintStyle: style.copyWith(color: AppColors.foregroundQuaternary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.spacing2),
        ValueListenableBuilder(
          valueListenable: controller,
          builder: (context, value, _) => Text(
            '${value.text.characters.length}/${MealPolicy.memoMaxLength}',
            key: const ValueKey('meal-save-memo-count'),
            textAlign: TextAlign.right,
            style: AppTypography.bodySmR.copyWith(
              color: AppColors.foregroundTertiary,
            ),
          ),
        ),
      ],
    );
  }
}
