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

  static const int _searchSize = MealPolicy.listMaxCount;
  static const int _pageSize = 50;

  /// 즐겨찾기·직접 등록은 개수 제한 없이 전체를 받음 (안전장치로 최대 20페이지)
  static const int _maxPages = 20;

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

  /// MO-MEAL-010: 즐겨찾기 등록 시각 순, 30개 제한 없음 (정렬은 서버 기준)
  @override
  Future<List<MealFood>> favorites() => _all('/api/foods/favorites');

  /// MO-MEAL-010: 최근 먹은 음식 최대 30개
  @override
  Future<List<MealFood>> recent() =>
      _page('/api/foods/recent', {'page': 0, 'size': MealPolicy.listMaxCount});

  /// MO-MEAL-010: 직접 등록 음식 전체
  @override
  Future<List<MealFood>> userFoods() => _all('/api/foods/custom');

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
        // 메모 필드명은 Swagger 확인 필요, 사진 업로드 API 는 아직 없음
        if (record.memo.trim().isNotEmpty) 'memo': record.memo.trim(),
      },
    );
  }

  /// MO-MEAL-050 음식 직접 등록 (영양 성분은 기준 섭취량 기준)
  @override
  Future<MealFood> createCustomFood(MealFood food) async {
    final json = await _client.post(
      '/api/foods/custom',
      body: {
        'name': food.name,
        'brand': ?food.brand,
        'servingAmount': food.servingGram,
        'servingUnit': food.servingUnit.toUpperCase(),
        'nutrients': {
          'kcal': food.kcal,
          for (final MapEntry(:key, :value) in _nutrientKeys.entries)
            if (value(food) case final v?) key: v,
        },
      },
    ) as Map<String, dynamic>;
    return _food(
      json,
      nutrients: json['nutrients'] as Map<String, dynamic>? ?? const {},
    );
  }

  /// 서버 영양성분 키 (탄·단·지 외 키 이름은 Swagger 확인 필요)
  static final Map<String, double? Function(MealFood)> _nutrientKeys = {
    'carbohydrateG': (f) => f.carbs,
    'proteinG': (f) => f.protein,
    'fatG': (f) => f.fat,
    'sugarsG': (f) => f.sugar,
    'dietaryFiberG': (f) => f.fiber,
    'saturatedFatG': (f) => f.saturatedFat,
    'transFatG': (f) => f.transFat,
    'fattyAcidG': (f) => f.fattyAcid,
    'unsaturatedFatG': (f) => f.unsaturatedFat,
    'cholesterolMg': (f) => f.cholesterol,
    'sodiumMg': (f) => f.sodium,
    'caffeineMg': (f) => f.caffeine,
  };

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
    final (foods, _) = await _fetchPage(path, query);
    return foods;
  }

  /// 마지막 페이지까지 이어서 받음
  Future<List<MealFood>> _all(String path) async {
    final all = <MealFood>[];
    for (var page = 0; page < _maxPages; page++) {
      final (foods, last) = await _fetchPage(path, {
        'page': page,
        'size': _pageSize,
      });
      all.addAll(foods);
      if (last || foods.length < _pageSize) break;
    }
    return all;
  }

  Future<(List<MealFood>, bool)> _fetchPage(
    String path,
    Map<String, Object?> query,
  ) async {
    final json = await _client.get(path, query: query) as Map<String, dynamic>;
    final content = json['content'] as List<dynamic>? ?? const [];
    return (
      [for (final item in content) _summary(item as Map<String, dynamic>)],
      json['last'] == true,
    );
  }

  MealFood _summary(Map<String, dynamic> json) {
    final food = _food(json, nutrients: {'kcal': json['kcal']});
    if (json['favorite'] is bool)
      _favorites[food.id] = json['favorite'] as bool;
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
      sugar: asDouble(nutrients['sugarsG']),
      fiber: asDouble(nutrients['dietaryFiberG']),
      saturatedFat: asDouble(nutrients['saturatedFatG']),
      transFat: asDouble(nutrients['transFatG']),
      fattyAcid: asDouble(nutrients['fattyAcidG']),
      unsaturatedFat: asDouble(nutrients['unsaturatedFatG']),
      cholesterol: asDouble(nutrients['cholesterolMg']),
      sodium: asDouble(nutrients['sodiumMg']),
      caffeine: asDouble(nutrients['caffeineMg']),
    );
  }
}
