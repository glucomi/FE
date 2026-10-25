import 'package:glucomi/features/meal/meal_models.dart';

/// 음식 검색 / 즐겨찾기 / 최근 먹은 음식 / 직접 등록 데이터
/// (서버 API 가 준비되면 이 인터페이스를 구현해서 교체)
abstract class MealFoodRepository {
  Future<List<MealFood>> search(String query);
  Future<List<MealFood>> favorites();
  Future<List<MealFood>> recent();
  Future<List<MealFood>> userFoods();

  Future<bool> isFavorite(MealFood food);
  Future<void> setFavorite(MealFood food, {required bool favorite});

  /// 음식을 눌렀을 때 영양 성분까지 채운 상세 (목록에는 kcal 만 있을 수 있음)
  Future<MealFood> detail(MealFood food);

  /// 기록하기 — 담은 음식들을 한 번에 저장
  Future<void> saveRecord(MealRecord record);
}

/// 미리보기 / 테스트용 메모리 저장소
class SampleMealFoodRepository implements MealFoodRepository {
  SampleMealFoodRepository({
    List<MealFood>? foods,
    Set<String>? favoriteIds,
    List<String>? recentIds,
  }) : _foods = foods ?? sampleFoods,
       _favoriteIds = favoriteIds ?? {'black-rice', 'user-multigrain', 'user-tuna'},
       _recentIds = [
         ...(recentIds ?? ['gimbap', 'rolled-egg', 'tuna-kimchi-stew']),
       ];

  /// 기록이 하나도 없는 상태
  factory SampleMealFoodRepository.empty() => SampleMealFoodRepository(
    foods: sampleFoods.where((f) => f.source == MealFoodSource.db).toList(),
    favoriteIds: {},
    recentIds: [],
  );

  final List<MealFood> _foods;
  final Set<String> _favoriteIds;
  final List<String> _recentIds;

  List<MealFood> _byIds(Iterable<String> ids) => [
    for (final id in ids) ..._foods.where((f) => f.id == id),
  ];

  @override
  Future<List<MealFood>> search(String query) async {
    final q = query.replaceAll(' ', '');
    if (q.isEmpty) return const [];
    return _foods.where((f) => f.name.replaceAll(' ', '').contains(q)).toList();
  }

  @override
  Future<List<MealFood>> favorites() async => _byIds(_favoriteIds);

  @override
  Future<List<MealFood>> recent() async => _byIds(_recentIds);

  @override
  Future<List<MealFood>> userFoods() async =>
      _foods.where((f) => f.source == MealFoodSource.user).toList();

  @override
  Future<bool> isFavorite(MealFood food) async =>
      _favoriteIds.contains(food.id);

  @override
  Future<void> setFavorite(MealFood food, {required bool favorite}) async {
    if (favorite) {
      _favoriteIds.add(food.id);
    } else {
      _favoriteIds.remove(food.id);
    }
  }

  @override
  Future<MealFood> detail(MealFood food) async => food;

  /// 예시 저장소는 화면에만 반영 (최근 먹은 음식 맨 앞으로)
  @override
  Future<void> saveRecord(MealRecord record) async {
    for (final entry in record.entries.reversed) {
      _recentIds
        ..remove(entry.food.id)
        ..insert(0, entry.food.id);
    }
  }

  /// Figma 예시 음식 + 자주 먹는 음식 몇 가지 (영양 정보는 기준량 기준)
  static const sampleFoods = <MealFood>[
    MealFood(id: 'black-rice', name: '흑미밥', servingGram: 150, kcal: 122, carbs: 26, protein: 3, fat: 1),
    MealFood(id: 'multigrain-rice', name: '잡곡밥', servingGram: 100, kcal: 108, carbs: 23, protein: 3, fat: 0.5),
    MealFood(id: 'hetbahn', name: '햇반', category: '가공 식품', brand: 'CJ', servingGram: 210, kcal: 315, carbs: 69, protein: 5, fat: 1),
    MealFood(id: 'white-rice', name: '백미밥', servingGram: 210, kcal: 310, carbs: 68, protein: 5, fat: 0.6),
    MealFood(id: 'fried-rice', name: '볶음밥', servingGram: 300, kcal: 520, carbs: 75, protein: 14, fat: 18),
    MealFood(id: 'bibimbap', name: '비빔밥', servingGram: 400, kcal: 550, carbs: 85, protein: 20, fat: 14),
    MealFood(id: 'gimbap', name: '김밥', servingGram: 230, kcal: 400, carbs: 64, protein: 12, fat: 11),
    MealFood(id: 'tuna-kimchi-stew', name: '참치김치찌개', servingGram: 400, kcal: 250, carbs: 10, protein: 18, fat: 15),
    MealFood(id: 'rolled-egg', name: '계란말이', servingGram: 100, kcal: 150, carbs: 2, protein: 11, fat: 11),
    MealFood(id: 'bean-sprouts', name: '콩나물무침', servingGram: 70, kcal: 30, carbs: 3, protein: 2, fat: 1),
    MealFood(id: 'water', name: '물', servingGram: 200, kcal: 0),
    MealFood(id: 'jjajangmyeon', name: '짜장면', servingGram: 650, kcal: 797, carbs: 133, protein: 22, fat: 19),
    MealFood(id: 'chicken-breast', name: '닭가슴살', category: '가공 식품', servingGram: 100, kcal: 109, carbs: 0, protein: 23, fat: 1),
    MealFood(id: 'user-multigrain', name: '잡곡밥', source: MealFoodSource.user, servingGram: 100, kcal: 108, carbs: 23, protein: 3, fat: 0.5),
    MealFood(id: 'user-tuna', name: '참치', source: MealFoodSource.user, brand: '동원', servingGram: 150, kcal: 210, carbs: 0, protein: 30, fat: 10),
  ];
}
