import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/drug/drug_models.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';
import 'package:glucomi/shared/widgets/record/record_select_field.dart';
import 'package:glucomi/shared/widgets/record/record_sheets.dart';
import 'package:glucomi/shared/widgets/record/record_text_input.dart';

/// MO-DRUG-020 복약-등록
///
/// - (a) 약 종류 미선택: 등록하기 비활성, 제품명 입력 미노출
/// - (b) 약 종류 선택 → COM-POP-09
/// - (c) 약 종류 선택 후: 제품명 입력(선택, 20자) 노출, 등록하기 활성
///
/// 등록하면 [SavedDrug] 를 돌려주며 직전 화면으로 복귀 (뒤로가기는 null)
class DrugRegisterScreen extends StatefulWidget {
  const DrugRegisterScreen({super.key, required this.repository});

  final DrugRepository repository;

  @override
  State<DrugRegisterScreen> createState() => _DrugRegisterScreenState();
}

class _DrugRegisterScreenState extends State<DrugRegisterScreen> {
  final _productController = TextEditingController();
  DrugType? _type;
  bool _busy = false;

  @override
  void dispose() {
    _productController.dispose();
    super.dispose();
  }

  /// 입력·변경 내용이 있어도 확인 팝업 없이 바로 닫힘
  void _back() => Navigator.of(context).maybePop();

  Future<void> _pickType() async {
    final index = await showRecordOptionSheet(
      context,
      title: '복용약 선택',
      options: [for (final t in DrugType.values) t.label],
      selected: _type?.index,
    );
    if (index == null || !mounted) return;
    setState(() => _type = DrugType.values[index]);
  }

  Future<void> _register() async {
    final type = _type;
    if (type == null || _busy) return;
    setState(() => _busy = true);
    try {
      // 중복 약이어도 별다른 조치 없이 등록
      final drug = await widget.repository.addSavedDrug(
        type: type,
        productName: _productController.text,
      );
      if (mounted) Navigator.of(context).pop(drug);
    } catch (e) {
      _showError(e, '복용약을 등록하지 못했어요.');
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
    final type = _type;
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(title: '복용약 등록하기', onBack: _busy ? null : _back),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.spacing4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 약 종류는 필수 항목 (정책 MO-DRUG-020 ②)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '복용약 선택',
                          style: AppTypography.headingH3.copyWith(
                            color: AppColors.foregroundPrimary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.spacing05),
                        SvgPicture.asset(
                          'assets/record/required_mark.svg',
                          width: 8,
                          height: 8,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.spacing2),
                    RecordSelectField(
                      key: const ValueKey('drug-register-type'),
                      placeholder: '약 종류를 선택해주세요',
                      value: type?.label,
                      onTap: _busy ? null : _pickType,
                    ),
                    if (type != null) ...[
                      const SizedBox(height: AppSpacing.spacing2),
                      RecordTextInput(
                        fieldKey: const ValueKey('drug-register-product'),
                        controller: _productController,
                        hintText: '제품명을 입력해주세요(선택)',
                        maxLength: DrugPolicy.productNameMaxLength,
                        enabled: !_busy,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            BottomActionBar(
              key: const ValueKey('drug-register-submit'),
              label: '등록하기',
              onPressed: type == null || _busy ? null : _register,
            ),
          ],
        ),
      ),
    );
  }
}
