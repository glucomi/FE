import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// 인슐린 분류 (Figma COM-POP-08 분류 헤더 순서)
enum InsulinCategory {
  rapidActing('초속효성'),
  shortActing('속효성'),
  intermediate('중간형'),
  longActing('장기형'),
  premixed('혼합형'),
  combination('복합형');

  const InsulinCategory(this.label);

  final String label;
}

/// 인슐린 제품 (제품명 + 분류)
@immutable
class InsulinProduct {
  const InsulinProduct(this.name, this.category);

  final String name;
  final InsulinCategory category;

  /// 레버미어플렉스펜주 (장기형)
  String get displayName => '$name (${category.label})';

  @override
  bool operator ==(Object other) =>
      other is InsulinProduct &&
      other.name == name &&
      other.category == category;

  @override
  int get hashCode => Object.hash(name, category);
}

/// COM-POP-08 인슐린 종류 목록
///
/// 정책서는 '노션 문서 참고'라서 Figma COM-POP-08 디자인에 있는 목록을 그대로 씀
/// (서버 API 가 생기면 서버 목록으로 교체)
abstract final class InsulinCatalog {
  static const List<InsulinProduct> products = [
    InsulinProduct('노보래피드플렉스펜주', InsulinCategory.rapidActing),
    InsulinProduct('룸제브퀵펜주', InsulinCategory.rapidActing),
    InsulinProduct('애피드라주솔로스타', InsulinCategory.rapidActing),
    InsulinProduct('피아스프플렉스터치주', InsulinCategory.rapidActing),
    InsulinProduct('휴마로그주', InsulinCategory.rapidActing),
    InsulinProduct('휴물린알주', InsulinCategory.shortActing),
    InsulinProduct('인슈라타드HM주', InsulinCategory.intermediate),
    InsulinProduct('휴물린엔주', InsulinCategory.intermediate),
    InsulinProduct('글라지아프리필드펜', InsulinCategory.longActing),
    InsulinProduct('란투스주솔로스타', InsulinCategory.longActing),
    InsulinProduct('레버미어플렉스펜주', InsulinCategory.longActing),
    InsulinProduct('베이사글라퀵펜', InsulinCategory.longActing),
    InsulinProduct('투제오주솔로스타', InsulinCategory.longActing),
    InsulinProduct('트레시바플렉스터치주', InsulinCategory.longActing),
    InsulinProduct('노모믹스50플렉스펜주', InsulinCategory.premixed),
    InsulinProduct('노보믹스30플렉스펜주', InsulinCategory.premixed),
    InsulinProduct('리조덱플렉스터치주', InsulinCategory.premixed),
    InsulinProduct('믹스타드30HM주', InsulinCategory.premixed),
    InsulinProduct('휴마로그믹스25퀵펜주', InsulinCategory.premixed),
    InsulinProduct('휴마로그믹스50퀵펜주', InsulinCategory.premixed),
    InsulinProduct('휴물린 70/30 퀵펜주', InsulinCategory.premixed),
    InsulinProduct('솔리쿠아펜주(10~40)', InsulinCategory.combination),
    InsulinProduct('솔리쿠아펜주(30~60)', InsulinCategory.combination),
    InsulinProduct('줄토피플렉스터치주', InsulinCategory.combination),
  ];

  /// 분류 순서대로 묶은 목록 (제품이 없는 분류는 빠짐)
  static Map<InsulinCategory, List<InsulinProduct>> get byCategory => {
    for (final category in InsulinCategory.values)
      if (products.any((p) => p.category == category))
        category: [
          for (final p in products)
            if (p.category == category) p,
        ],
  };
}

/// 투여량 (U) 입력 규칙 (MO-INSULIN-010 ⑪, MO-INSULIN-020 ④ 동일)
abstract final class InsulinDosePolicy {
  /// 최소값 0.5U (0 또는 0.5 미만 저장 불가)
  static const double minDose = 0.5;

  /// 최대값 30U (정책서 '정수부 최대 3자리, 최대 표기 100.0' 과 충돌 — 확인 필요)
  static const double maxDose = 30;

  /// 0.5U 단위
  static const double step = 0.5;

  /// 정수부 최대 자릿수
  static const int maxIntegerDigits = 3;

  /// 저장 가능한 값이면 숫자로, 아니면 null ('3.' 처럼 소수점으로 끝나도 3 으로 봄)
  static double? parse(String text) {
    var t = text.trim();
    if (t.endsWith('.')) t = t.substring(0, t.length - 1);
    if (t.isEmpty) return null;
    final value = double.tryParse(t);
    if (value == null) return null;
    if (value < minDose || value > maxDose) return null;
    if ((value / step) != (value / step).roundToDouble()) return null;
    return value;
  }

  /// 1 → '1', 1.5 → '1.5'
  static String format(double dose) => dose == dose.roundToDouble()
      ? dose.toInt().toString()
      : dose.toStringAsFixed(1);

  /// 1 → '1U'
  static String formatWithUnit(double dose) => '${format(dose)}U';
}

/// 투여량 필드 입력 정리
///
/// - 숫자와 소수점(.) 1개만 허용, 그 외 문자·두 번째 소수점은 막음
/// - 소수 1자리까지, 소수 자리에는 0 또는 5만
/// - 선행 0 정리 ('01' → '1', '00.5' → '0.5'), 소수점으로 시작하면 0 보정 ('.5' → '0.5')
/// - 정수부 최대 3자리
/// - 최대값을 넘으면 마지막 자리부터 지워서 최대값 안으로 맞춤
class InsulinDoseInputFormatter extends TextInputFormatter {
  const InsulinDoseInputFormatter();

  static final RegExp _allowed = RegExp(r'^[0-9.]*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = normalize(newValue.text);
    if (text == null) return oldValue;
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  /// 정리한 문자열. 허용하지 않는 입력이면 null
  static String? normalize(String input) {
    if (input.isEmpty) return input;
    if (!_allowed.hasMatch(input)) return null;
    if ('.'.allMatches(input).length > 1) return null;

    var text = input.startsWith('.') ? '0$input' : input;
    final dot = text.indexOf('.');
    var integer = dot < 0 ? text : text.substring(0, dot);
    final decimal = dot < 0 ? null : text.substring(dot + 1);

    integer = integer.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (integer.length > InsulinDosePolicy.maxIntegerDigits) return null;
    if (decimal != null) {
      if (decimal.length > 1) return null;
      if (decimal.isNotEmpty && decimal != '0' && decimal != '5') return null;
    }
    text = decimal == null ? integer : '$integer.$decimal';

    while (text.isNotEmpty && _valueOf(text) > InsulinDosePolicy.maxDose) {
      text = text.substring(0, text.length - 1);
    }
    return text;
  }

  static double _valueOf(String text) {
    final t = text.endsWith('.') ? text.substring(0, text.length - 1) : text;
    return double.tryParse(t) ?? 0;
  }
}

/// 내 인슐린 한 개 (MO-INSULIN-020 에서 등록한 인슐린 종류 + 투여량)
@immutable
class MyInsulin {
  const MyInsulin({
    required this.id,
    required this.product,
    required this.dose,
  });

  final String id;
  final InsulinProduct product;

  /// 등록할 때 입력한 투여량 (U)
  final double dose;

  @override
  bool operator ==(Object other) =>
      other is MyInsulin &&
      other.id == id &&
      other.product == product &&
      other.dose == dose;

  @override
  int get hashCode => Object.hash(id, product, dose);
}

/// 인슐린 투여 기록 한 건
@immutable
class InsulinRecord {
  InsulinRecord({
    this.id,
    required DateTime time,
    required this.product,
    required this.dose,
    this.memo = '',
  }) : time = DateTime(time.year, time.month, time.day, time.hour, time.minute);

  /// 저장 전이면 null
  final String? id;

  /// 투여 일시 (분 단위)
  final DateTime time;
  final InsulinProduct product;
  final double dose;

  /// 메모 (선택, 최대 [InsulinRecordPolicy.memoMaxLength]자)
  final String memo;

  InsulinRecord copyWith({String? id}) => InsulinRecord(
    id: id ?? this.id,
    time: time,
    product: product,
    dose: dose,
    memo: memo,
  );

  @override
  bool operator ==(Object other) =>
      other is InsulinRecord &&
      other.id == id &&
      other.time == time &&
      other.product == product &&
      other.dose == dose &&
      other.memo == memo;

  @override
  int get hashCode => Object.hash(id, time, product, dose, memo);
}

abstract final class InsulinRecordPolicy {
  /// 메모 최대 글자 수 (COM-04)
  static const int memoMaxLength = 1000;
}

/// 인슐린 화면을 닫을 때 돌려주는 결과 (닫기·변경 없는 수정은 null)
@immutable
class InsulinRecordResult {
  const InsulinRecordResult.saved(InsulinRecord this.record) : deleted = false;
  const InsulinRecordResult.deleted() : record = null, deleted = true;

  /// 저장된 기록 (삭제면 null)
  final InsulinRecord? record;
  final bool deleted;
}

/// 이미 내 인슐린에 있는 종류를 다시 등록하려 할 때
class DuplicateInsulinException implements Exception {
  const DuplicateInsulinException(this.product);

  final InsulinProduct product;

  @override
  String toString() => 'DuplicateInsulinException(${product.name})';
}

/// 인슐린 저장소 (서버 API 가 준비되면 이 인터페이스를 구현해서 교체)
abstract class InsulinRepository {
  /// 내 인슐린 목록 (등록한 순서)
  Future<List<MyInsulin>> myInsulins();

  /// 내 인슐린 등록. 같은 종류가 이미 있으면 [DuplicateInsulinException]
  Future<MyInsulin> addMyInsulin(InsulinProduct product, double dose);

  Future<void> deleteMyInsulin(String id);

  /// 기록 저장. [InsulinRecord.id] 가 있으면 그 기록을 수정
  Future<InsulinRecord> saveRecord(InsulinRecord record);

  Future<void> deleteRecord(String id);
}

/// 미리보기 / 서버 연동 전 메모리 저장소
class SampleInsulinRepository implements InsulinRepository {
  SampleInsulinRepository({List<MyInsulin> myInsulins = const []})
    : _myInsulins = [...myInsulins];

  /// 디자인 예시와 같은 내 인슐린 3개
  factory SampleInsulinRepository.withExamples() => SampleInsulinRepository(
    myInsulins: const [
      MyInsulin(
        id: 'sample-1',
        product: InsulinProduct('노보래피드플렉스펜주', InsulinCategory.rapidActing),
        dose: 1,
      ),
      MyInsulin(
        id: 'sample-2',
        product: InsulinProduct('레버미어플렉스펜주', InsulinCategory.longActing),
        dose: 1,
      ),
      MyInsulin(
        id: 'sample-3',
        product: InsulinProduct('트레시바플렉스터치주', InsulinCategory.longActing),
        dose: 1,
      ),
    ],
  );

  final List<MyInsulin> _myInsulins;
  final Map<String, InsulinRecord> _records = {};
  int _seq = 0;

  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}-${_seq++}';

  /// 저장된 기록 (테스트·미리보기 확인용)
  List<InsulinRecord> get records => List.unmodifiable(_records.values);

  @override
  Future<List<MyInsulin>> myInsulins() async => List.unmodifiable(_myInsulins);

  @override
  Future<MyInsulin> addMyInsulin(InsulinProduct product, double dose) async {
    if (_myInsulins.any((m) => m.product == product)) {
      throw DuplicateInsulinException(product);
    }
    final added = MyInsulin(id: _nextId('my'), product: product, dose: dose);
    _myInsulins.add(added);
    return added;
  }

  @override
  Future<void> deleteMyInsulin(String id) async {
    _myInsulins.removeWhere((m) => m.id == id);
  }

  @override
  Future<InsulinRecord> saveRecord(InsulinRecord record) async {
    final saved = record.id == null
        ? record.copyWith(id: _nextId('record'))
        : record;
    _records[saved.id!] = saved;
    return saved;
  }

  @override
  Future<void> deleteRecord(String id) async {
    _records.remove(id);
  }
}
