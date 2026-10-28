import 'dart:math' as math;

class CalculationOutcome {
  const CalculationOutcome({this.value, this.error, this.text});

  final double? value;
  final String? error;
  final String? text;

  bool get isError => error != null;
}

class CalculatorLogic {
  static const String divisionByZeroMessage = "Can't divide by 0";
  static const String invalidExpressionMessage = 'Invalid expression';

  static String sanitizeExpression(String input) {
    return input
        .replaceAll('−', '-')
        .replaceAll('–', '-')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll(' ', '')
        .replaceAll('√', 'sqrt(')
        .replaceAll('π', 'pi');
  }

  static String displayFriendly(String expression) {
    final value = expression.replaceAll(' ', '');
    return value
        .replaceAll('sqrt(', '√(')
        .replaceAll('pi', 'π')
        .replaceAll('*', '×')
        .replaceAll('/', '÷');
  }

  static String formatResult(double value) {
    if (value.isNaN || value.isInfinite) {
      return 'Error';
    }

    final magnitude = value.abs();
    if (magnitude < 1e-12) {
      return '0';
    }

    if (magnitude >= 1e12 || (magnitude > 0 && magnitude < 1e-8)) {
      final scientific = value.toStringAsExponential(6);
      final parts = scientific.split('e');
      final mantissa = parts.first
          .replaceAll(RegExp(r'\.0+$'), '')
          .replaceAll(RegExp(r'(\.\d*?)0+$'), r'$1');
      final exponent = parts.length == 2 ? parts[1] : '0';
      return '$mantissa e$exponent';
    }

    var text = value.toStringAsFixed(12);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      text = text.replaceFirst(RegExp(r'\.$'), '');
    }
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return value.toStringAsFixed(6);
    }
    if (parsed == parsed.roundToDouble()) {
      return parsed.toInt().toString();
    }
    return text;
  }

  static CalculationOutcome evaluate(
    String expression, {
    bool radians = false,
  }) {
    try {
      final cleaned = sanitizeExpression(expression.trim());
      if (cleaned.isEmpty) {
        return const CalculationOutcome(value: 0, text: '0');
      }

      if (_hasUnbalancedParentheses(cleaned)) {
        return const CalculationOutcome(error: invalidExpressionMessage);
      }

      final parser = _ExpressionParser(cleaned, radians: radians);
      final result = parser.parse();
      if (result.isNaN || result.isInfinite) {
        return const CalculationOutcome(error: invalidExpressionMessage);
      }
      return CalculationOutcome(value: result, text: formatResult(result));
    } on _DivisionByZeroException {
      return const CalculationOutcome(error: divisionByZeroMessage);
    } on FormatException {
      return const CalculationOutcome(error: invalidExpressionMessage);
    } on Exception {
      return const CalculationOutcome(error: invalidExpressionMessage);
    }
  }

  static bool _hasUnbalancedParentheses(String expression) {
    var depth = 0;
    for (final char in expression.split('')) {
      if (char == '(') {
        depth++;
      } else if (char == ')') {
        depth--;
        if (depth < 0) {
          return true;
        }
      }
    }
    return depth != 0;
  }
}

class _ExpressionParser {
  _ExpressionParser(this.expression, {required this.radians})
      : _tokens = _tokenize(expression);

  final String expression;
  final bool radians;
  final List<_Token> _tokens;
  int _index = 0;

  double parse() {
    final value = _parseAddSubtract();
    if (_index != _tokens.length) {
      throw const FormatException('Unexpected trailing token');
    }
    return value;
  }

  static bool _isDigitChar(String char) {
    if (char.isEmpty || char.length > 1) {
      return false;
    }
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static List<_Token> _tokenize(String source) {
    final tokens = <_Token>[];
    var index = 0;

    while (index < source.length) {
      final char = source[index];

      if (char == ' ') {
        index += 1;
        continue;
      }

      if (_isDigitChar(char) || char == '.') {
        final start = index;
        var dotCount = 0;

        while (index < source.length) {
          final current = source[index];
          if (current == '.') {
            dotCount++;
            if (dotCount > 1) {
              throw const FormatException('Multiple decimals');
            }
          } else if (!_isDigitChar(current)) {
            break;
          }
          index += 1;
        }

        final numberText = source.substring(start, index);
        if (numberText == '.') {
          throw const FormatException('Invalid number');
        }

        final number = double.tryParse(numberText);
        if (number == null) {
          throw const FormatException('Invalid number');
        }

        tokens.add(_Token.number(number));
        continue;
      }

      if (char.toLowerCase() == 's' ||
          char.toLowerCase() == 'c' ||
          char.toLowerCase() == 't' ||
          char.toLowerCase() == 'l' ||
          char.toLowerCase() == 'p' ||
          char.toLowerCase() == 'e') {
        final start = index;
        while (index < source.length) {
          final current = source[index];
          final isLetter = current.toLowerCase() != current.toUpperCase();
          if (isLetter || _isDigitChar(current) || current == '_') {
            index += 1;
            continue;
          }
          break;
        }

        final identifier = source.substring(start, index).toLowerCase();
        switch (identifier) {
          case 'sin':
          case 'cos':
          case 'tan':
          case 'ln':
          case 'log':
          case 'sqrt':
            tokens.add(_Token.function(identifier));
            continue;
          case 'pi':
            tokens.add(_Token.number(math.pi));
            continue;
          case 'e':
            tokens.add(_Token.number(math.e));
            continue;
          default:
            throw FormatException('Unknown symbol: $identifier');
        }
      }

      switch (char) {
        case '(':
          tokens.add(const _Token.openParen());
          index += 1;
          break;
        case ')':
          tokens.add(const _Token.closeParen());
          index += 1;
          break;
        case '+':
          final previous = tokens.isEmpty ? null : tokens.last;
          if (previous == null ||
              previous.type == _TokenType.operator ||
              previous.type == _TokenType.openParen) {
            index += 1;
            continue;
          }
          tokens.add(const _Token.operator('+'));
          index += 1;
          break;
        case '-':
          final previous = tokens.isEmpty ? null : tokens.last;
          if (previous == null ||
              previous.type == _TokenType.operator ||
              previous.type == _TokenType.openParen) {
            tokens.add(const _Token.operator('u-'));
          } else {
            tokens.add(const _Token.operator('-'));
          }
          index += 1;
          break;
        case '*':
        case '/':
        case '%':
        case '^':
          tokens.add(_Token.operator(char));
          index += 1;
          break;
        default:
          throw FormatException('Unexpected character: $char');
      }
    }

    return tokens;
  }

  double _parseAddSubtract() {
    var result = _parseMultiplyDivide();
    while (_matchOperator('+') || _matchOperator('-')) {
      final operator = _previous().stringValue;
      final right = _parseMultiplyDivide();
      result = operator == '+' ? result + right : result - right;
    }
    return result;
  }

  double _parseMultiplyDivide() {
    var result = _parsePower();

    while (true) {
      if (_matchOperator('*')) {
        final right = _parsePower();
        result *= right;
      } else if (_matchOperator('/')) {
        final right = _parsePower();
        if (right == 0) {
          throw const _DivisionByZeroException();
        }
        result /= right;
      } else if (_matchOperator('%')) {
        result = result / 100;
      } else {
        return result;
      }
    }
  }

  double _parsePower() {
    var result = _parseUnary();
    if (_matchOperator('^')) {
      final exponent = _parsePower();
      result = math.pow(result, exponent).toDouble();
    }
    return result;
  }

  double _parseUnary() {
    if (_matchOperator('u-')) {
      return -_parseUnary();
    }
    if (_matchOperator('+')) {
      return _parseUnary();
    }
    return _parsePrimary();
  }

  double _parsePrimary() {
    if (_matchNumber()) {
      return _previous().numberValue;
    }

    if (_matchFunction()) {
      final functionName = _previous().stringValue;
      if (_matchOpenParen()) {
        final value = _parseAddSubtract();
        _expectCloseParen();
        return _applyFunction(functionName, value);
      }
      final value = _parseUnary();
      return _applyFunction(functionName, value);
    }

    if (_matchOpenParen()) {
      final value = _parseAddSubtract();
      _expectCloseParen();
      return value;
    }

    throw const FormatException('Unexpected token');
  }

  double _applyFunction(String name, double value) {
    switch (name) {
      case 'sin':
        return math.sin(radians ? value : value * math.pi / 180);
      case 'cos':
        return math.cos(radians ? value : value * math.pi / 180);
      case 'tan':
        return math.tan(radians ? value : value * math.pi / 180);
      case 'ln':
        return math.log(value);
      case 'log':
        return math.log(value) / math.log(10);
      case 'sqrt':
        return math.sqrt(value);
      default:
        throw const FormatException('Unsupported function');
    }
  }

  bool _matchNumber() {
    if (_index < _tokens.length && _tokens[_index].type == _TokenType.number) {
      _index += 1;
      return true;
    }
    return false;
  }

  bool _matchFunction() {
    if (_index < _tokens.length && _tokens[_index].type == _TokenType.function) {
      _index += 1;
      return true;
    }
    return false;
  }

  bool _matchOpenParen() {
    if (_index < _tokens.length && _tokens[_index].type == _TokenType.openParen) {
      _index += 1;
      return true;
    }
    return false;
  }

  void _expectCloseParen() {
    if (_index >= _tokens.length || _tokens[_index].type != _TokenType.closeParen) {
      throw const FormatException('Missing closing parenthesis');
    }
    _index += 1;
  }

  bool _matchOperator(String value) {
    if (_index < _tokens.length &&
        _tokens[_index].type == _TokenType.operator &&
        _tokens[_index].stringValue == value) {
      _index += 1;
      return true;
    }
    return false;
  }

  _Token _previous() => _tokens[_index - 1];
}

enum _TokenType { number, operator, function, openParen, closeParen }

class _Token {
  const _Token.number(this.numberValue)
      : type = _TokenType.number,
        stringValue = '';

  const _Token.operator(this.stringValue)
      : type = _TokenType.operator,
        numberValue = 0;

  const _Token.function(this.stringValue)
      : type = _TokenType.function,
        numberValue = 0;

  const _Token.openParen()
      : type = _TokenType.openParen,
        numberValue = 0,
        stringValue = '';

  const _Token.closeParen()
      : type = _TokenType.closeParen,
        numberValue = 0,
        stringValue = '';

  final _TokenType type;
  final double numberValue;
  final String stringValue;
}

class _DivisionByZeroException implements Exception {
  const _DivisionByZeroException();
}
