import 'package:flutter/material.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/exercise/exercise_models.dart';
import 'package:glucomi/features/exercise/widgets/exercise_option_tile.dart';
import 'package:glucomi/features/meal/widgets/meal_search_bar.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';
import 'package:glucomi/shared/widgets/app_toast.dart';
import 'package:glucomi/shared/widgets/bottom_action_bar.dart';

/// MO-EXERCISE-020 운동 추가
///
/// 운동 하나를 골라 추가하기를 누르면 그 [Exercise] 를 돌려줌 (뒤로가기는 null)
class ExerciseAddScreen extends StatefulWidget {
  const ExerciseAddScreen({super.key, required this.repository});

  final ExerciseRepository repository;

  @override
  State<ExerciseAddScreen> createState() => _ExerciseAddScreenState();
}

class _ExerciseAddScreenState extends State<ExerciseAddScreen> {
  final _searchController = TextEditingController();

  List<Exercise> _recent = const [];
  List<Exercise> _popular = const [];
  List<Exercise> _catalog = const [];
  bool _loaded = false;

  /// 엔터로 검색을 실행한 검색어 (null 이면 기본 목록)
  String? _query;
  List<Exercise> _results = const [];

  /// 단일 선택 — 섹션이 달라도 같은 운동이면 함께 선택 표시
  Exercise? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = widget.repository;
    final List<List<Exercise>> results;
    try {
      results = await Future.wait([
        repo.recent(),
        repo.popular(),
        repo.catalog(),
      ]);
    } catch (e) {
      _showError(e, '운동 목록을 불러오지 못했어요.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _recent = results[0];
      _popular = results[1];
      _catalog = results[2];
      _loaded = true;
    });
  }

  /// 엔터 시 검색 수행
  Future<void> _search(String text) async {
    final q = text.trim();
    if (q.isEmpty) {
      _reset();
      return;
    }
    final List<Exercise> results;
    try {
      results = await widget.repository.search(q);
    } catch (e) {
      _showError(e, '운동을 검색하지 못했어요.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _query = q;
      _results = results;
    });
  }

  void _reset() {
    if (_query == null) return;
    setState(() {
      _query = null;
      _results = const [];
    });
  }

  void _clear() {
    _searchController.clear();
    _reset();
  }

  /// 탭 시 선택 (선택 해제 없음)
  void _select(Exercise e) => setState(() => _selected = e);

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
            AppHeaderBar(onBack: () => Navigator.of(context).maybePop()),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.spacing4,
                AppSpacing.spacing4,
                AppSpacing.spacing4,
                0,
              ),
              child: MealSearchBar(
                controller: _searchController,
                hintText: '운동명을 검색해보세요',
                maxLength: ExercisePolicy.maxQueryLength,
                onSubmitted: _search,
                onChanged: (v) {
                  if (v.isEmpty) _reset();
                },
                onClear: _clear,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.translucent,
                child: _buildBody(),
              ),
            ),
            BottomActionBar(
              key: const ValueKey('exercise-add-confirm'),
              label: '추가하기',
              onPressed: _selected == null
                  ? null
                  : () => Navigator.of(context).pop(_selected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_loaded) return const SizedBox.shrink();
    const padding = EdgeInsets.fromLTRB(
      18,
      AppSpacing.spacing3,
      20,
      AppSpacing.spacing6,
    );

    if (_query != null) {
      if (_results.isEmpty) {
        return const SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.spacing4,
            vertical: AppSpacing.spacing4,
          ),
          child: ExerciseNoResult(),
        );
      }
      return SingleChildScrollView(
        padding: padding,
        child: ExerciseOptionSection(
          key: const ValueKey('exercise-section-search'),
          title: '검색 결과',
          exercises: _results,
          selected: _selected,
          onSelect: _select,
        ),
      );
    }

    final sections = <Widget>[
      // 기록 이력이 1건 이상일 때만 노출
      if (_recent.isNotEmpty)
        ExerciseOptionSection(
          key: const ValueKey('exercise-section-recent'),
          title: '최근 기록한 운동',
          exercises: _recent,
          selected: _selected,
          onSelect: _select,
        ),
      if (_popular.isNotEmpty)
        ExerciseOptionSection(
          key: const ValueKey('exercise-section-popular'),
          title: '인기 운동',
          exercises: _popular,
          selected: _selected,
          onSelect: _select,
        ),
      ExerciseOptionSection(
        key: const ValueKey('exercise-section-all'),
        title: '운동 목록',
        exercises: _catalog,
        selected: _selected,
        onSelect: _select,
      ),
    ];

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.spacing6),
            sections[i],
          ],
        ],
      ),
    );
  }
}
