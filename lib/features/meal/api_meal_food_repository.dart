import 'package:glucomi/core/api/api_client.dart';
import 'package:glucomi/features/meal/meal_food_repository.dart';
import 'package:glucomi/features/meal/meal_models.dart';

/// 서버 음식 API 저장소 (/api/foods, /api/meal-records)
class ApiMealFoodRepository implements MealFoodRepository {
  ApiMealFoodRepository([ApiClient? client])
    : _client = client ?? ApiClient.instance;

  final ApiClient _client;

  /// 목록/상세에서 받은 즐겨찾기 여부 (음식 id → 즐겨찾기)
  final Map<String, bool> _favorites = {};

  static const int _searchSize = 30;
  static const int _listSize = 50;

  @override
  Future<List<MealFood>> search(String query) async {
    final keyword = query.trim();
    if (keyword.isEmpty) return const [];
    // sort 는 보내지 않음 (서버가 이름 짧은 순으로 정렬)
    return _page('/api/foods', {
      'keyword': keyword,
      'page': 0,
      'size': _searchSize,
    });
  }

  @override
  Future<List<MealFood>> favorites() =>
      _page('/api/foods/favorites', {'page': 0, 'size': _listSize});

  @override
  Future<List<MealFood>> recent() =>
      _page('/api/foods/recent', {'page': 0, 'size': _listSize});

  @override
  Future<List<MealFood>> userFoods() =>
      _page('/api/foods/custom', {'page': 0, 'size': _listSize});

  @override
  Future<bool> isFavorite(MealFood food) async => _favorites[food.id] ?? false;

  @override
  Future<void> setFavorite(MealFood food, {required bool favorite}) async {
    final path = '/api/foods/${food.id}/favorite';
    if (favorite) {
      await _client.post(path);
    } else {
      await _client.delete(path);
    }
    _favorites[food.id] = favorite;
  }

  @override
  Future<MealFood> detail(MealFood food) async {
    final json =
        await _client.get('/api/foods/${food.id}') as Map<String, dynamic>;
    final nutrients = json['nutrients'] as Map<String, dynamic>? ?? const {};
    final detailed = _food(json, nutrients: nutrients);
    _favorites[detailed.id] = json['favorite'] == true;
    return detailed;
  }

  @override
  Future<void> saveRecord(MealRecord record) async {
    await _client.post(
      '/api/meal-records',
      body: {
        'eatenAt': formatApiDateTime(record.time),
        'items': [for (final entry in record.entries) _item(entry)],
      },
    );
  }

  /// MO-MEAL-050 음식 직접 등록 (화면 연결 전, 영양 성분은 기준량 기준)
  Future<MealFood> createCustomFood({
    required String name,
    required double servingAmount,
    required String servingUnit,
    required double kcal,
    String? brand,
    double? carbs,
    double? protein,
    double? fat,
  }) async {
    final json =
        await _client.post(
              '/api/foods/custom',
              body: {
                'name': name,
                'brand': ?brand,
                'servingAmount': servingAmount,
                'servingUnit': servingUnit.toUpperCase(),
                'nutrients': {
                  'kcal': kcal,
                  'carbohydrateG': ?carbs,
                  'proteinG': ?protein,
                  'fatG': ?fat,
                },
              },
            )
            as Map<String, dynamic>;
    return _food(
      json,
      nutrients: json['nutrients'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// 식사 기록 음식 한 개
  ///
  /// Swagger 에서 이 항목 스키마가 약관 동의 Item 으로 덮여 보여서 필드명은
  /// 설명(unit = 기준 단위 G/ML 또는 SERVING) 기준으로 맞춤 — 백엔드 확인 필요
  Map<String, Object> _item(MealEntry entry) => {
    'foodId': int.tryParse(entry.food.id) ?? entry.food.id,
    'amount': entry.amount,
    'unit': switch (entry.unit) {
      MealUnit.gram => entry.food.servingUnit.toUpperCase(),
      MealUnit.serving => 'SERVING',
    },
  };

  Future<List<MealFood>> _page(String path, Map<String, Object?> query) async {
    final json = await _client.get(path, query: query) as Map<String, dynamic>;
    final content = json['content'] as List<dynamic>? ?? const [];
    return [
      for (final item in content) _summary(item as Map<String, dynamic>),
    ];
  }

  MealFood _summary(Map<String, dynamic> json) {
    final food = _food(json, nutrients: {'kcal': json['kcal']});
    if (json['favorite'] is bool) _favorites[food.id] = json['favorite'] as bool;
    return food;
  }

  MealFood _food(
    Map<String, dynamic> json, {
    required Map<String, dynamic> nutrients,
  }) {
    final custom = json['source'] == 'CUSTOM';
    return MealFood(
      id: '${json['foodId']}',
      name: json['name'] as String? ?? '',
      source: custom ? MealFoodSource.user : MealFoodSource.db,
      category: json['category'] == 'PROCESSED' ? '가공 식품' : '일반 식품',
      brand: (json['brand'] as String?)?.trim().isEmpty ?? true
          ? null
          : json['brand'] as String,
      servingGram: asDouble(json['servingAmount']) ?? 0,
      servingUnit: json['servingUnit'] == 'ML' ? 'ml' : 'g',
      kcal: asDouble(nutrients['kcal']) ?? 0,
      carbs: asDouble(nutrients['carbohydrateG']) ?? 0,
      protein: asDouble(nutrients['proteinG']) ?? 0,
      fat: asDouble(nutrients['fatG']) ?? 0,
    );
  }
}
