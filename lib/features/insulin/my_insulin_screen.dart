import 'package:flutter/material.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';
import 'package:glucomi/features/insulin/insulin_register_screen.dart';
import 'package:glucomi/features/insulin/widgets/insulin_fields.dart';
import 'package:glucomi/shared/widgets/app_confirm_dialog.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';
import 'package:glucomi/shared/widgets/record/saved_item_card.dart';

/// MO-INSULIN-030 내 인슐린
///
/// - (a) 기록없음: 빈 상태 문구 / (b) 기록있음: 제품명 + 분류 | 투여량 카드
/// - X: COM-POP-05 삭제 확인 → 목록에서 지움 (모두 지우면 (a))
/// - 새 인슐린 추가하기: MO-INSULIN-020, 등록하면 목록에 바로 반영
class MyInsulinScreen extends StatefulWidget {
  const MyInsulinScreen({super.key, required this.repository});

  final InsulinRepository repository;

  @override
  State<MyInsulinScreen> createState() => _MyInsulinScreenState();
}

class _MyInsulinScreenState extends State<MyInsulinScreen> {
  List<MyInsulin>? _insulins;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.repository.myInsulins();
    if (!mounted) return;
    setState(() => _insulins = list);
  }

  Future<void> _add() async {
    await Navigator.of(context).push<MyInsulin>(
      MaterialPageRoute(
        builder: (_) => InsulinRegisterScreen(
          repository: widget.repository,
          openMyInsulinAfterSave: false,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _delete(MyInsulin insulin) async {
    if (_busy) return;
    final confirmed = await showDeleteConfirmDialog(context);
    if (!confirmed || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.deleteMyInsulin(insulin.id);
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insulins = _insulins;
    return Scaffold(
      backgroundColor: AppColors.neutralsBackground,
      body: SafeArea(
        child: Column(
          children: [
            AppHeaderBar(
              title: '내 인슐린',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.neutralsSurface,
                child: insulins == null
                    ? const SizedBox.expand()
                    : insulins.isEmpty
                    ? const Center(
                        key: ValueKey('my-insulin-empty'),
                        child: InsulinEmptyMessage(),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.spacing4),
                        itemCount: insulins.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.spacing2),
                        itemBuilder: (context, index) {
                          final insulin = insulins[index];
                          // {제품명} / {분류} | {투여량}
                          return SavedItemCard(
                            key: ValueKey('my-insulin-${insulin.id}'),
                            title: insulin.product.name,
                            subtitle:
                                '${insulin.product.category.label} | '
                                '${InsulinDosePolicy.formatWithUnit(insulin.dose)}',
                            onDelete: _busy ? null : () => _delete(insulin),
                          );
                        },
                      ),
              ),
            ),
            BottomActionBar(
              key: const ValueKey('my-insulin-add'),
              label: '새 인슐린 추가하기',
              onPressed: _busy ? null : _add,
            ),
          ],
        ),
      ),
    );
  }
}
