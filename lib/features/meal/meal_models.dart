import 'package:flutter/foundation.dart';

/// 음식 데이터 출처 (COM-01 data 속성)
enum MealFoodSource {
  /// 식품 DB에 있는 음식
  db,

  /// 사용자가 직접 등록한 음식
  user,
}

/// 음식 한 가지 (영양 정보는 기준량 [servingGram] 기준)
@immutable
class MealFood {
  const MealFood({
    required this.id,
    required this.name,
    required this.servingGram,
    required this.kcal,
    this.source = MealFoodSource.db,
    this.category = '일반 식품',
    this.brand,
    this.carbs = 0,
    this.protein = 0,
    this.fat = 0,
    this.servingUnit = 'g',
  });

  final String id;
  final String name;
  final MealFoodSource source;

  /// DB 음식 분류 (일반 식품 / 가공 식품)
  final String category;

  /// 브랜드명 (예: 동원)
  final String? brand;

  /// 기준량 (단위는 [servingUnit])
  final double servingGram;

  /// 기준량 단위 (g / ml)
  final String servingUnit;
  final double kcal;
  final double carbs;
  final double protein;
  final double fat;

  /// 목록 윗줄에 보이는 회색 라벨 (예: ['직접등록', '동원'])
  List<String> get labels => switch (source) {
    MealFoodSource.db => [category],
    MealFoodSource.user => ['직접등록', ?brand],
  };

  @override
  bool operator ==(Object other) => other is MealFood && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// 섭취량 단위
enum MealUnit {
  gram('g'),
  serving('인분');

  const MealUnit(this.label);

  final String label;
}

/// 기록할 음식 한 개 (음식 + 먹은 양)
@immutable
class MealEntry {
  const MealEntry({
    required this.food,
    required this.amount,
    this.unit = MealUnit.gram,
  });

  /// 기준량만큼 먹은 것으로 시작
  factory MealEntry.initial(MealFood food) =>
      MealEntry(food: food, amount: food.servingGram);

  final MealFood food;
  final double amount;
  final MealUnit unit;

  double get grams => switch (unit) {
    MealUnit.gram => amount,
    MealUnit.serving => amount * food.servingGram,
  };

  double get _ratio => food.servingGram == 0 ? 0 : grams / food.servingGram;

  double get kcal => food.kcal * _ratio;
  double get carbs => food.carbs * _ratio;
  double get protein => food.protein * _ratio;
  double get fat => food.fat * _ratio;

  MealEntry copyWith({double? amount, MealUnit? unit}) => MealEntry(
    food: food,
    amount: amount ?? this.amount,
    unit: unit ?? this.unit,
  );
}

/// 음식 기록하기 결과 (기록하기를 누르면 홈으로 돌려줌)
@immutable
class MealRecord {
  const MealRecord({required this.time, required this.entries});

  final DateTime time;
  final List<MealEntry> entries;

  double get kcal => entries.fold(0, (sum, e) => sum + e.kcal);
  double get carbs => entries.fold(0, (sum, e) => sum + e.carbs);

  /// 홈 기록 카드 제목 (예: 흑미밥 외 2개)
  String get title {
    if (entries.isEmpty) return '';
    final first = entries.first.food.name;
    return entries.length == 1 ? first : '$first 외 ${entries.length - 1}개';
  }
}

/// 숫자를 소수점 없이 또는 한 자리까지 표시 (150 / 1.5)
String formatMealNumber(double value) {
  final rounded = (value * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? rounded.toStringAsFixed(0)
      : rounded.toStringAsFixed(1);
}
