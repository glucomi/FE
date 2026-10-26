import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:glucomi/core/api/api_exception.dart';
import 'package:glucomi/design_system/tokens/app_tokens.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_models.dart';
import 'package:glucomi/features/meal/widgets/meal_amount_sheet.dart';
import 'package:glucomi/features/meal/widgets/meal_cart_bar.dart';
import 'package:glucomi/features/meal/widgets/meal_food_tile.dart';
import 'package:glucomi/features/meal/widgets/meal_search_bar.dart';
import 'package:glucomi/features/meal/widgets/meal_search_panels.dart';
import 'package:glucomi/shared/widgets/app_header_bar.dart';

/// MO-MEAL-010 / 020 음식 기록하기
/// 음식을 골라 담고 기록하기를 누르면 [MealRecord] 를 돌려주며 닫힘
class MealRecordScreen extends StatefulWidget {
  const MealRecordScreen({
    super.key,
    required this.repository,
    this.clock = DateTime.now,
    this.onRegisterFood,
  });

  final MealFoodRepository repository;

  /// 기록 시각 (테스트용으로 바꿀 수 있음)
  final DateTime Function() clock;

  /// 직접 등록 화면으로 이동 (없으면 준비 중 안내)
  final VoidCallback? onRegisterFood;

  @override
  State<MealRecordScreen> createState() => _MealRecordScreenState();
}

class _MealRecordScreenState extends State<MealRecordScreen> {
  static const _tabs = ['즐겨찾기', '최근 먹은 음식', '직접 등록'];
  static const _emptyMessages = [
    ('아직 즐겨찾기한 음식이 없어요', '자주 먹은 음식을 즐겨찾기하고 쉽게 찾아보세요'),
    ('아직 최근 먹은 음식이 없어요', '먹은 음식이 있다면 직접 등록해보세요'),
    ('아직 직접 등록한 음식이 없어요', '지금부터 음식을 기록해보세요'),
  ];

  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();

  String _query = '';
  int _tab = 0;
  List<List<MealFood>> _tabFoods = const [[], [], []];
  List<MealFood> _results = const [];
  final List<MealEntry> _cart = [];
  bool _saving = false;

  bool get _searching => _query.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadTabs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadTabs() async {
    final repo = widget.repository;
    try {
      final lists = await Future.wait([
        repo.favorites(),
        repo.recent(),
        repo.userFoods(),
      ]);
      if (mounted) setState(() => _tabFoods = lists);
    } catch (e) {
      _showError(e, '음식 목록을 불러오지 못했어요.');
    }
  }

  Future<void> _onQueryChanged(String text) async {
    final query = text.trim();
    setState(() {
      _query = query;
      if (query.isEmpty) _results = const [];
    });
    if (query.isEmpty) return;

    final List<MealFood> results;
    try {
      results = await widget.repository.search(query);
    } catch (e) {
      if (query == _query) _showError(e, '검색하지 못했어요.');
      return;
    }
    // 입력이 바뀌는 사이에 늦게 온 결과는 버림
    if (mounted && query == _query) setState(() => _results = results);
  }

  // MO-MEAL-020: 초기화 후 '즐겨찾기' 탭으로 복귀
  void _clearSearch() {
    _searchController.clear();
    setState(() => _tab = 0);
    _onQueryChanged('');
  }

  MealEntry? _cartEntryFor(MealFood food) {
    for (final entry in _cart) {
      if (entry.food == food) return entry;
    }
    return null;
  }

  Future<void> _openFood(MealFood food) async {
    _searchFocus.unfocus();
    final repo = widget.repository;
    final MealFood detailed;
    final bool favorite;
    try {
      // 목록에는 열량만 있을 수 있어서 영양 성분을 채운 상세로 엶
      detailed = await repo.detail(food);
      favorite = await repo.isFavorite(detailed);
    } catch (e) {
      _showError(e, '음식 정보를 불러오지 못했어요.');
      return;
    }
    if (!mounted) return;

    final current = _cartEntryFor(food);
    final entry = await showMealAmountSheet(
      context,
      initial: current == null
          ? MealEntry.initial(detailed)
          : MealEntry(food: detailed, amount: current.amount, unit: current.unit),
      favorite: favorite,
      onFavoriteChanged: (value) async {
        try {
          await repo.setFavorite(detailed, favorite: value);
        } catch (e) {
          _showError(e, '즐겨찾기를 바꾸지 못했어요.');
          return;
        }
        await _loadTabs();
      },
      onNutritionInfo: () => _notReady('영양정보'),
    );
    if (entry == null || !mounted) return;

    setState(() {
      final index = _cart.indexWhere((e) => e.food == food);
      if (index >= 0) {
        _cart[index] = entry;
      } else {
        _cart.add(entry);
      }
    });
  }

  Future<void> _submit() async {
    if (_saving) return;
    final record = MealRecord(
      time: widget.clock(),
      entries: List.unmodifiable(_cart),
    );
    setState(() => _saving = true);
    try {
      await widget.repository.saveRecord(record);
    } catch (e) {
      if (mounted) setState(() => _saving = false);
      _showError(e, '식단을 기록하지 못했어요. 다시 시도해 주세요.');
      return;
    }
    if (mounted) Navigator.of(context).pop(record);
  }

  void _showError(Object error, String fallback) {
    if (!mounted) return;
    final message = error is ApiException ? error.message : fallback;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _registerFood() {
    if (widget.onRegisterFood != null) {
      widget.onRegisterFood!();
    } else {
      _notReady('직접 등록');
    }
  }

  void _notReady(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$feature 준비 중입니다.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutralsSurface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppHeaderBar(
              title: '음식 기록하기',
              iconLeft: Semantics(
                button: true,
                label: '닫기',
                child: GestureDetector(
                  key: const ValueKey('meal-close'),
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                  child: SvgPicture.asset(
                    'assets/meal/close.svg',
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.spacing4,
                AppSpacing.spacing4,
                AppSpacing.spacing4,
                _searching ? AppSpacing.spacing4 : 0,
              ),
              decoration: const BoxDecoration(
                color: AppColors.neutralsBackground,
                border: Border(
                  bottom: BorderSide(color: AppColors.borderDefault),
                ),
              ),
              child: Column(
                children: [
                  MealSearchBar(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    // MO-MEAL-010: 엔터(검색) 시 검색 수행, 입력을 다 지우면 탭으로 복귀
                    onChanged: (text) {
                      if (text.trim().isEmpty) _clearSearch();
                    },
                    onSubmitted: _onQueryChanged,
                    onClear: _clearSearch,
                  ),
                  if (!_searching) ...[
                    const SizedBox(height: AppSpacing.spacing6),
                    MealTabs(
                      labels: _tabs,
                      selectedIndex: _tab,
                      onSelect: (i) => setState(() => _tab = i),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(child: _searching ? _buildResults() : _buildTab()),
            if (_cart.isNotEmpty)
              MealCartBar(
                entries: _cart,
                onEdit: (entry) => _openFood(entry.food),
                onRemove: (entry) => setState(() => _cart.remove(entry)),
                onSubmit: _submit,
              ),
          ],
        ),
      ),
    );
  }

  Widget _tile(MealFood food) => MealFoodTile(
    key: ValueKey('meal-food-${food.id}'),
    food: food,
    selected: _cartEntryFor(food) != null,
    onTap: () => _openFood(food),
  );

  Widget _buildTab() {
    final foods = _tabFoods[_tab];
    final isRegisterTab = _tab == 2;
    final bottomInset = _cart.isEmpty
        ? MediaQuery.paddingOf(context).bottom
        : 0.0;
    final (title, message) = _emptyMessages[_tab];

    return Stack(
      children: [
        if (foods.isEmpty)
          Align(
            alignment: Alignment.topCenter,
            child: MealEmptyMessage(title: title, message: message),
          )
        else
          ListView(
            padding: EdgeInsets.only(bottom: isRegisterTab ? 72 : 0),
            children: [for (final food in foods) _tile(food)],
          ),
        if (isRegisterTab)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppSpacing.spacing4 + bottomInset,
            child: Center(child: MealRegisterButton(onTap: _registerFood)),
          ),
      ],
    );
  }

  Widget _buildResults() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        for (final food in _results) _tile(food),
        MealRegisterSuggestion(query: _query, onRegister: _registerFood),
        const MealSearchTips(),
      ],
    );
  }
}
