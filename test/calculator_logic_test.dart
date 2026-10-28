import 'package:calculator/calculator_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalculatorLogic', () {
    test('respects precedence', () {
      final result = CalculatorLogic.evaluate('2 + 3 * 4');
      expect(result.isError, isFalse);
      expect(result.text, '14');
    });

    test('handles chained operations', () {
      final result = CalculatorLogic.evaluate('10 - 2 * 3 + 4');
      expect(result.isError, isFalse);
      expect(result.text, '8');
    });

    test('handles decimals', () {
      final result = CalculatorLogic.evaluate('0.1 + 0.2');
      expect(result.isError, isFalse);
      expect(result.text, '0.3');
    });

    test('division by zero returns error', () {
      final result = CalculatorLogic.evaluate('5 / 0');
      expect(result.isError, isTrue);
      expect(result.error, CalculatorLogic.divisionByZeroMessage);
    });

    test('supports percent', () {
      final result = CalculatorLogic.evaluate('50% * 200');
      expect(result.isError, isFalse);
      expect(result.text, '100');
    });

    test('supports parentheses', () {
      final result = CalculatorLogic.evaluate('(2 + 3) * 4');
      expect(result.isError, isFalse);
      expect(result.text, '20');
    });

    test('handles scientific functions', () {
      final result = CalculatorLogic.evaluate('sin(30)', radians: false);
      expect(result.isError, isFalse);
      expect(result.text, '0.5');
    });

    test('rejects invalid expression without throwing', () {
      final result = CalculatorLogic.evaluate('2 +');
      expect(result.isError, isTrue);
      expect(result.error, CalculatorLogic.invalidExpressionMessage);
    });
  });
}
