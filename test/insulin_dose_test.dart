import 'package:flutter_test/flutter_test.dart';
import 'package:glucomi/features/insulin/insulin_models.dart';

void main() {
  String? normalize(String s) => InsulinDoseInputFormatter.normalize(s);

  group('투여량 입력 정리 (MO-INSULIN-010 ⑪)', () {
    test('숫자와 소수점 1개만 허용', () {
      expect(normalize('1a'), isNull);
      expect(normalize('-1'), isNull);
      expect(normalize('1.5.'), isNull);
      expect(normalize('12'), '12');
    });

    test('소수 1자리, 0 또는 5만', () {
      expect(normalize('1.5'), '1.5');
      expect(normalize('1.0'), '1.0');
      expect(normalize('1.3'), isNull);
      expect(normalize('1.55'), isNull);
    });

    test('선행 0 정리, 소수점 시작 시 0 보정', () {
      expect(normalize('01'), '1');
      expect(normalize('00.5'), '0.5');
      expect(normalize('.5'), '0.5');
      expect(normalize('.'), '0.');
    });

    test('최대값을 넘으면 마지막 자리부터 지움', () {
      expect(normalize('30'), '30');
      expect(normalize('30.5'), '30.');
      expect(normalize('35'), '3');
    });
  });

  group('저장 유효성', () {
    test('0.5U 이상 30U 이하, 0.5 단위', () {
      expect(InsulinDosePolicy.parse(''), isNull);
      expect(InsulinDosePolicy.parse('0'), isNull);
      expect(InsulinDosePolicy.parse('0.'), isNull);
      expect(InsulinDosePolicy.parse('0.5'), 0.5);
      expect(InsulinDosePolicy.parse('3.'), 3);
      expect(InsulinDosePolicy.parse('30'), 30);
      expect(InsulinDosePolicy.parse('30.5'), isNull);
    });

    test('표기', () {
      expect(InsulinDosePolicy.formatWithUnit(1), '1U');
      expect(InsulinDosePolicy.formatWithUnit(1.5), '1.5U');
    });
  });
}
