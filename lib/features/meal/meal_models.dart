import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:glucomi/design_system/tokens/app_colors.dart';

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
    this.sugar,
    this.fiber,
    this.saturatedFat,
    this.transFat,
    this.fattyAcid,
    this.unsaturatedFat,
    this.cholesterol,
    this.sodium,
    this.caffeine,
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

  /// 상세 영양성분 (g, 콜레스테롤·나트륨·카페인은 mg). 값이 없으면 null
  final double? sugar;
  final double? fiber;
  final double? saturatedFat;
  final double? transFat;
  final double? fattyAcid;
  final double? unsaturatedFat;
  final double? cholesterol;
  final double? sodium;
  final double? caffeine;

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

  /// 상세 영양성분도 먹은 양 기준으로 환산 (없는 값은 null 유지)
  double? scaled(double? perServing) =>
      perServing == null ? null : perServing * _ratio;

  MealEntry copyWith({MealFood? food, double? amount, MealUnit? unit}) =>
      MealEntry(
        food: food ?? this.food,
        amount: amount ?? this.amount,
        unit: unit ?? this.unit,
      );
}

/// 식사 사진 한 장 (MO-MEAL-040). [foodId] 가 있으면 사진 위에 음식칩 표시
@immutable
class MealPhoto {
  const MealPhoto({required this.bytes, this.foodId});

  final Uint8List bytes;

  /// 사진과 연결된 음식 (음식칩 탭 → 해당 음식 위치로 이동)
  final String? foodId;
}

/// 음식 기록하기 결과 (기록하기를 누르면 홈으로 돌려줌)
@immutable
class MealRecord {
  const MealRecord({
    required this.time,
    required this.entries,
    this.memo = '',
    this.photos = const [],
  });

  final DateTime time;
  final List<MealEntry> entries;

  /// 메모 (선택, 최대 [MealPolicy.memoMaxLength]자)
  final String memo;
  final List<MealPhoto> photos;

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

/// 음식 기록하기 정책 값
abstract final class MealPolicy {
  /// MO-MEAL-010: 검색어 최대 길이
  static const int searchMaxLength = 50;

  /// 검색 결과 / 최근 먹은 음식 최대 노출 개수
  static const int listMaxCount = 30;

  /// MO-MEAL-040: 메모 최대 길이
  static const int memoMaxLength = 1000;

  /// MO-MEAL-040: 사진 최대 장수
  static const int photoMaxCount = 10;

  /// COM-POP-01: 수량 최솟값
  static const double minAmount = 1;
}

/// 예상 혈당 변화 등급 (MO-MEAL-030). 색은 3단계 (좋음 / 주의 / 위험)
enum GlucoseGrade {
  aPlus('A+', 1 / 6),
  a('A', 2 / 6),
  bPlus('B+', 3 / 6),
  b('B', 4 / 6),
  c('C', 5 / 6),
  f('F', 1);

  const GlucoseGrade(this.label, this.fill);

  final String label;

  /// 게이지가 채워지는 비율 (0~1)
  final double fill;

  Color get color => switch (this) {
    aPlus || a => AppColors.accentsBrand,
    bPlus || b => AppColors.accentsWarning,
    c || f => AppColors.accentsDanger,
  };

  /// 등급 구간 (mg/dL). 세부 로직은 노션 문서 기준으로 맞춰야 함 — 임시값
  static GlucoseGrade of(double delta) {
    if (delta <= 5) return aPlus;
    if (delta <= 10) return a;
    if (delta <= 20) return bPlus;
    if (delta <= 30) return b;
    if (delta <= 50) return c;
    return f;
  }
}

/// 예상 혈당 변화량 (mg/dL) 임시 계산: 순탄수(탄수화물 - 식이섬유) 1g 당 약 1mg/dL
/// 서버 예측 API 가 생기면 [MealFoodRepository] 쪽으로 옮김
double estimateGlucoseDelta(MealEntry entry) {
  final netCarbs = entry.carbs - (entry.scaled(entry.food.fiber) ?? 0);
  return netCarbs <= 0 ? 0 : netCarbs.roundToDouble();
}

/// 받침 유무에 맞는 조사 (이/가, 을/를 …)
String josa(String word, String withFinal, String withoutFinal) {
  if (word.isEmpty) return withFinal;
  final code = word.runes.last;
  if (code < 0xAC00 || code > 0xD7A3) return withFinal;
  return (code - 0xAC00) % 28 == 0 ? withoutFinal : withFinal;
}
