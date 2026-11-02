import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/features/insulin/my_insulin_screen.dart';
import 'package:glucomi/features/insulin/widgets/insulin_fields.dart';
import 'package:glucomi/features/insulin/widgets/insulin_type_sheet.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';
import 'package:glucomi/shared/widgets/record/record_select_field.dart';

/// MO-INSULIN-020 인슐린 등록하기
///
/// - (a) 종류 미선택 → (b) COM-POP-08 → (c) 종류 선택 후 투여량 입력
/// - 등록하기: 종류 선택 + 투여량 유효 입력 시 활성. 같은 종류가 이미 있으면 안내 후 등록 안 함
/// - 등록 후: [openMyInsulinAfterSave] 면 내 인슐린(030)으로 바꿔 띄우고,
///   아니면(030 에서 들어온 경우) 등록한 [MyInsulin] 을 돌려주며 닫힘
class InsulinRegisterScreen extends StatefulWidget {
  const InsulinRegisterScreen({
    super.key,
    required this.repository,
    this.openMyInsulinAfterSave = true,
  });

  final InsulinRepository repository;
  final bool openMyInsulinAfterSave;

  @override
  State<InsulinRegisterScreen> createState() => _InsulinRegisterScreenState();
}

class _InsulinRegisterScreenState extends State<InsulinRegisterScreen> {
  final _doseController = TextEditingController();
  InsulinProduct? _product;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _doseController.addListener(_refresh);
  }

  @override
  void dispose() {
    _doseController.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  double? get _dose => InsulinDosePolicy.parse(_doseController.text);

  bool get _canSave => _product != null && _dose != null && !_busy;

  Future<void> _pickType() async {
    FocusScope.of(context).unfocus();
    final picked = await showInsulinTypeSheet(context, selected: _product);
    if (picked == null || !mounted) return;
    setState(() => _product = picked);
  }

  Future<void> _save() async {
    final product = _product;
    final dose = _dose;
    if (product == null || dose == null || _busy) return;
    FocusScope.of(context).unfocus();

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      final added = await widget.repository.addMyInsulin(product, dose);
      if (!mounted) return;
      showAppToastOn(messenger, '새 인슐린을 등록했어요.', type: AppToastType.success);
      if (widget.openMyInsulinAfterSave) {
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => MyInsulinScreen(repository: widget.repository),
          ),
        );
      } else {
        Navigator.of(context).pop(added);
      }
    } on DuplicateInsulinException {
      // COM-TOAST-02
      showAppToastOn(messenger, '이미 등록된 인슐린이에요', type: AppToastType.error);
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
            // ① 뒤로가기: 입력이 있어도 확인 없이 바로 이전 화면으로
            AppHeaderBar(
              title: '인슐린 등록하기',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(AppSpacing.spacing4),
                children: [
                  SizedBox(
                    height: AppSpacing.controlHeightSm,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '인슐린 선택',
                        style: AppTypography.headingH3.copyWith(
                          color: AppColors.foregroundPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.spacing2),
                  RecordSelectField(
                    key: const ValueKey('insulin-register-type'),
                    value: product?.displayName,
                    placeholder: '종류를 선택해주세요',
                    onTap: _busy ? null : _pickType,
                  ),
                  if (product != null) ...[
                    const SizedBox(height: AppSpacing.spacing2),
                    InsulinDoseInput(
                      controller: _doseController,
                      fieldKey: const ValueKey('insulin-register-dose'),
                    ),
                  ],
                ],
              ),
            ),
            BottomActionBar(
              key: const ValueKey('insulin-register-save'),
              label: '등록하기',
              onPressed: _canSave ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}
