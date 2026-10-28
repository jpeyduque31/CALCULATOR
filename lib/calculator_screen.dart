import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'calculator_logic.dart';
import 'widgets/calc_button.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final Future<void> Function(ThemeMode) onThemeChanged;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  static const String _historyKey = 'calculator_history';

  final FocusNode _focusNode = FocusNode();
  String _expression = '';
  String _result = '0';
  bool _scientificMode = false;
  bool _isRadians = true;
  List<String> _history = <String>[];
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _prefs = prefs;
      _history = (prefs.getStringList(_historyKey) ?? <String>[]).take(50).toList();
      _updatePreview();
    });
  }

  Future<void> _saveHistory() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setStringList(_historyKey, _history.take(50).toList());
    _prefs = prefs;
  }

  void _updatePreview() {
    final expression = _expression.trim();
    if (expression.isEmpty) {
      _result = '0';
      return;
    }

    final outcome = CalculatorLogic.evaluate(expression, radians: _isRadians);
    if (outcome.isError) {
      _result = outcome.error ?? CalculatorLogic.invalidExpressionMessage;
      return;
    }

    _result = outcome.text ?? '0';
  }

  void _handleDigit(String digit) {
    if (_expression.isEmpty && digit == '0') {
      return;
    }

    setState(() {
      if (_expression == '0' && digit != '0') {
        _expression = digit;
      } else {
        _expression += digit;
      }
      _updatePreview();
    });
  }

  void _handleOperator(String operatorSymbol) {
    setState(() {
      if (_expression.isEmpty) {
        if (operatorSymbol == '-') {
          _expression = '-';
        }
        return;
      }

      final last = _expression.substring(_expression.length - 1);
      final normalized = operatorSymbol == '×' ? '*' : (operatorSymbol == '÷' ? '/' : operatorSymbol);
      if (['+', '-', '*', '/', '^', '%'].contains(last)) {
        _expression = _expression.substring(0, _expression.length - 1) + normalized;
      } else {
        _expression += normalized;
      }
      _updatePreview();
    });
  }

  void _handleDecimal() {
    setState(() {
      if (_expression.isEmpty) {
        _expression = '0.';
      } else {
        final lastNumber = _expression.split(RegExp(r'[+\-*/%^]')).last;
        if (!lastNumber.contains('.')) {
          _expression += '.';
        }
      }
      _updatePreview();
    });
  }

  void _handleFunction(String functionName) {
    setState(() {
      _expression += functionName;
      _updatePreview();
    });
  }

  void _handlePercent() {
    setState(() {
      if (_expression.isEmpty) {
        return;
      }
      _expression += '%';
      _updatePreview();
    });
  }

  void _toggleSign() {
    setState(() {
      if (_expression.isEmpty) {
        _expression = '-';
      } else if (_expression.startsWith('-')) {
        _expression = _expression.substring(1);
      } else {
        _expression = '-$_expression';
      }
      _updatePreview();
    });
  }

  void _backspace() {
    setState(() {
      if (_expression.isEmpty) {
        return;
      }
      _expression = _expression.substring(0, _expression.length - 1);
      _updatePreview();
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
      _result = '0';
    });
  }

  void _appendParenthesis(String value) {
    setState(() {
      _expression += value;
      _updatePreview();
    });
  }

  Future<void> _evaluateExpression() async {
    final expression = _expression.trim();
    if (expression.isEmpty) {
      return;
    }

    final outcome = CalculatorLogic.evaluate(expression, radians: _isRadians);
    if (outcome.isError) {
      setState(() {
        _result = outcome.error ?? '0';
      });
      return;
    }

    final value = outcome.text ?? '0';
    setState(() {
      _expression = value;
      _result = value;
      _history.insert(0, '$expression = $value');
      _history = _history.take(50).toList();
    });
    await _saveHistory();
  }

  void _handleKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) {
      return;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.backspace) {
      _backspace();
      return;
    }
    if (key == LogicalKeyboardKey.escape) {
      _clear();
      return;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      _evaluateExpression();
      return;
    }

    if (key == LogicalKeyboardKey.digit0) {
      _handleDigit('0');
    } else if (key == LogicalKeyboardKey.digit1) {
      _handleDigit('1');
    } else if (key == LogicalKeyboardKey.digit2) {
      _handleDigit('2');
    } else if (key == LogicalKeyboardKey.digit3) {
      _handleDigit('3');
    } else if (key == LogicalKeyboardKey.digit4) {
      _handleDigit('4');
    } else if (key == LogicalKeyboardKey.digit5) {
      _handleDigit('5');
    } else if (key == LogicalKeyboardKey.digit6) {
      _handleDigit('6');
    } else if (key == LogicalKeyboardKey.digit7) {
      _handleDigit('7');
    } else if (key == LogicalKeyboardKey.digit8) {
      _handleDigit('8');
    } else if (key == LogicalKeyboardKey.digit9) {
      _handleDigit('9');
    } else if (key == LogicalKeyboardKey.period) {
      _handleDecimal();
    } else if (key == LogicalKeyboardKey.numpadAdd || key == LogicalKeyboardKey.add) {
      _handleOperator('+');
    } else if (key == LogicalKeyboardKey.numpadSubtract || key == LogicalKeyboardKey.minus) {
      _handleOperator('-');
    } else if (key == LogicalKeyboardKey.numpadMultiply) {
      _handleOperator('×');
    } else if (key == LogicalKeyboardKey.numpadDivide || key == LogicalKeyboardKey.slash) {
      _handleOperator('÷');
    } else if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.numpadEqual) {
      _evaluateExpression();
    }
  }

  void _showHistorySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() => _history.clear());
                        await _saveHistory();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Clear'),
                    ),
                  ],
                ),
                if (_history.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('No calculations yet.'),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _history.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final entry = _history[index];
                        return ListTile(
                          title: Text(entry),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onTap: () {
                            final expression = entry.split('=').first.trim();
                            setState(() {
                              _expression = expression;
                              _updatePreview();
                            });
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _copyResult() {
    final text = _result;
    if (text.isEmpty || text == '0') {
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied: $text'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  List<Widget> _buildScientificButtons() {
    return <Widget>[
      CalcButton(label: 'sin', onPressed: () => _handleFunction('sin(')),
      CalcButton(label: 'cos', onPressed: () => _handleFunction('cos(')),
      CalcButton(label: 'tan', onPressed: () => _handleFunction('tan(')),
      CalcButton(label: 'ln', onPressed: () => _handleFunction('ln(')),
      CalcButton(label: 'log', onPressed: () => _handleFunction('log(')),
      CalcButton(label: '√', onPressed: () => _handleFunction('sqrt(')),
      CalcButton(label: 'x²', onPressed: () => _handleFunction('^2')),
      CalcButton(label: 'xʸ', onPressed: () => _handleOperator('^')),
      CalcButton(label: 'π', onPressed: () => _handleFunction('pi')),
      CalcButton(label: 'e', onPressed: () => _handleFunction('e')),
      CalcButton(label: '(', onPressed: () => _appendParenthesis('(')),
      CalcButton(label: ')', onPressed: () => _appendParenthesis(')')),
    ];
  }

  List<Widget> _buildStandardButtons() {
    return <Widget>[
      CalcButton(label: 'AC', secondary: true, onPressed: _clear),
      CalcButton(label: '⌫', secondary: true, onPressed: _backspace),
      CalcButton(label: '%', secondary: true, onPressed: _handlePercent),
      CalcButton(label: '÷', accent: true, onPressed: () => _handleOperator('÷')),
      CalcButton(label: '7', onPressed: () => _handleDigit('7')),
      CalcButton(label: '8', onPressed: () => _handleDigit('8')),
      CalcButton(label: '9', onPressed: () => _handleDigit('9')),
      CalcButton(label: '×', accent: true, onPressed: () => _handleOperator('×')),
      CalcButton(label: '4', onPressed: () => _handleDigit('4')),
      CalcButton(label: '5', onPressed: () => _handleDigit('5')),
      CalcButton(label: '6', onPressed: () => _handleDigit('6')),
      CalcButton(label: '−', accent: true, onPressed: () => _handleOperator('-')),
      CalcButton(label: '1', onPressed: () => _handleDigit('1')),
      CalcButton(label: '2', onPressed: () => _handleDigit('2')),
      CalcButton(label: '3', onPressed: () => _handleDigit('3')),
      CalcButton(label: '+', accent: true, onPressed: () => _handleOperator('+')),
      CalcButton(label: '±', secondary: true, onPressed: _toggleSign),
      CalcButton(label: '0', onPressed: () => _handleDigit('0')),
      CalcButton(label: '.', onPressed: _handleDecimal),
      CalcButton(label: '=', primary: true, onPressed: _evaluateExpression),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scientificButtons = _buildScientificButtons();
    final standardButtons = _buildStandardButtons();

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKey,
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 480;
                return Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          onPressed: _showHistorySheet,
                          tooltip: 'History',
                          icon: const Icon(Icons.history_rounded),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => widget.onThemeChanged(
                            widget.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
                          ),
                          tooltip: 'Theme',
                          icon: Icon(
                            widget.themeMode == ThemeMode.dark
                                ? Icons.light_mode_rounded
                                : Icons.dark_mode_rounded,
                          ),
                        ),
                        PopupMenuButton<ThemeMode>(
                          tooltip: 'Theme mode',
                          initialValue: widget.themeMode,
                          onSelected: widget.onThemeChanged,
                          itemBuilder: (context) => const <PopupMenuEntry<ThemeMode>>[
                            PopupMenuItem<ThemeMode>(
                              value: ThemeMode.system,
                              child: Text('Follow system'),
                            ),
                            PopupMenuItem<ThemeMode>(
                              value: ThemeMode.light,
                              child: Text('Light'),
                            ),
                            PopupMenuItem<ThemeMode>(
                              value: ThemeMode.dark,
                              child: Text('Dark'),
                            ),
                          ],
                          child: const Icon(Icons.settings_suggest_rounded),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => setState(() => _scientificMode = !_scientificMode),
                          child: Text(_scientificMode ? 'Standard' : 'Scientific'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _isRadians = !_isRadians),
                          child: Text(_isRadians ? 'Rad' : 'Deg'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      flex: 3,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                _expression.isEmpty ? '0' : _expression,
                                style: GoogleFonts.poppins(
                                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: scheme.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onLongPress: _copyResult,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  _result,
                                  maxLines: 1,
                                  style: GoogleFonts.poppins(
                                    textStyle: Theme.of(context).textTheme.displaySmall?.copyWith(
                                          color: scheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                                        ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (isCompact)
                              SizedBox(
                                height: 360,
                                child: GridView.builder(
                                  itemCount: standardButtons.length,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 4,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                    childAspectRatio: 1.15,
                                  ),
                                  itemBuilder: (context, index) => standardButtons[index],
                                  physics: const NeverScrollableScrollPhysics(),
                                ),
                              )
                            else
                              SizedBox(
                                height: 360,
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: scientificButtons,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: GridView.builder(
                                        itemCount: standardButtons.length,
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 4,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                          childAspectRatio: 1.15,
                                        ),
                                        itemBuilder: (context, index) => standardButtons[index],
                                        physics: const NeverScrollableScrollPhysics(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
