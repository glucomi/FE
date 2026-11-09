import 'package:flutter/material.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/drug/drug_models.dart';
import 'package:glucomi/features/drug/drug_register_screen.dart';
import 'package:glucomi/shared/widgets/app_confirm_dialog.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';
import 'package:glucomi/shared/widgets/record/record_sheets.dart';
import 'package:glucomi/shared/widgets/record/saved_item_card.dart';

/// MO-DRUG-030 복약-MY (내 복용약)
///
/// - (a) 기록없음: 안내 문구
/// - (b) 기록있음: {약 종류} + {제품명} 카드 목록, X → COM-POP-05 → 삭제
///   (복용약 선택 시트 COM-POP-07 도 같은 저장소를 보므로 함께 빠짐)
class MyDrugsScreen extends StatefulWidget {
  const MyDrugsScreen({super.key, required this.repository});

  final DrugRepository repository;

  @override
  State<MyDrugsScreen> createState() => _MyDrugsScreenState();
}

class _MyDrugsScreenState extends State<MyDrugsScreen> {
  List<SavedDrug>? _drugs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final drugs = await widget.repository.savedDrugs();
      if (mounted) setState(() => _drugs = drugs);
    } catch (e) {
      _showError(e, '내 복용약을 불러오지 못했어요.');
    }
  }

  Future<void> _add() async {
    final added = await Navigator.of(context).push<SavedDrug>(
      MaterialPageRoute(
        builder: (_) => DrugRegisterScreen(repository: widget.repository),
      ),
    );
    if (added != null) await _load();
  }

  Future<void> _delete(SavedDrug drug) async {
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed || !mounted) return;
    try {
      await widget.repository.deleteSavedDrug(drug.id);
    } catch (e) {
      _showError(e, '복용약을 삭제하지 못했어요.');
      return;
    }
    await _load();
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
    final drugs = _drugs;
    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '내 복용약',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: drugs == null
                  ? const SizedBox.shrink()
                  : drugs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.spacing16),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: RecordEmptyMessage(
                          title: '저장된 복용약이 없습니다',
                          message: '새 복용약을 추가해주세요',
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.spacing4),
                      itemCount: drugs.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.spacing2),
                      itemBuilder: (context, i) => SavedItemCard(
                        key: ValueKey('my-drug-${drugs[i].id}'),
                        title: drugs[i].type.label,
                        subtitle: drugs[i].productName ?? '',
                        onDelete: () => _delete(drugs[i]),
                      ),
                    ),
            ),
            BottomActionBar(
              key: const ValueKey('my-drugs-add'),
              label: '새 복용약 추가하기',
              onPressed: _add,
            ),
          ],
        ),
      ),
    );
  }
}
