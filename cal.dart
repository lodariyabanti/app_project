import 'package:flutter/material.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _current = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetCurrent = false;

  void _numClick(String text) {
    setState(() {
      if (_shouldResetCurrent) {
        _current = '';
        _shouldResetCurrent = false;
      }
      if (text == '.' && _current.contains('.')) return;
      _current = (_current == '0' && text != '.') ? text : _current + text;
      _display = _current;
    });
  }

  void _clear() {
    setState(() {
      _display = '0';
      _current = '';
      _firstOperand = null;
      _operator = null;
      _shouldResetCurrent = false;
    });
  }

  void _backspace() {
    setState(() {
      if (_current.isNotEmpty) {
        _current = _current.substring(0, _current.length - 1);
        _display = _current.isEmpty ? '0' : _current;
      }
    });
  }

  void _toggleSign() {
    setState(() {
      if (_current.isEmpty) return;
      if (_current.startsWith('-')) {
        _current = _current.substring(1);
      } else {
        _current = '-$_current';
      }
      _display = _current;
    });
  }

  void _percent() {
    setState(() {
      if (_current.isEmpty) return;
      final val = double.tryParse(_current) ?? 0.0;
      _current = (val / 100).toString();
      // remove trailing .0
      if (_current.endsWith('.0')) _current = _current.substring(0, _current.length - 2);
      _display = _current;
    });
  }

  void _operatorClick(String op) {
    setState(() {
      if (_current.isEmpty && _firstOperand == null) return;

      final parsed = double.tryParse(_current);
      if (_firstOperand == null && parsed != null) {
        _firstOperand = parsed;
      } else if (_operator != null && parsed != null) {
        _firstOperand = _calculate(_firstOperand!, parsed, _operator!);
        _display = _formatNumber(_firstOperand!);
      }

      _operator = op;
      _shouldResetCurrent = true;
    });
  }

  void _equals() {
    setState(() {
      final parsed = double.tryParse(_current);
      if (_firstOperand == null || _operator == null || parsed == null) return;

      final result = _calculate(_firstOperand!, parsed, _operator!);
      _display = _formatNumber(result);
      _current = _display;
      _firstOperand = null;
      _operator = null;
      _shouldResetCurrent = true;
    });
  }

  double _calculate(double a, double b, String op) {
    switch (op) {
      case '+':
        return a + b;
      case '-':
        return a - b;
      case '×':
        return a * b;
      case '÷':
        if (b == 0) return 0; // simple guard
        return a / b;
      default:
        return b;
    }
  }

  String _formatNumber(double val) {
    if (val == val.roundToDouble()) return val.toInt().toString();
    return val.toString();
  }

  Widget _buildButton(String label, {double flex = 1, VoidCallback? onTap, Color? color}) {
    return Expanded(
      flex: flex.toInt(),
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: color,
            elevation: 2,
          ),
          child: Text(
            label,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Calculator'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _display,
                      maxLines: 2,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    if (_operator != null && _firstOperand != null)
                      Text(
                        '${_formatNumber(_firstOperand!)} $_operator',
                        style: const TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ),

            // Buttons
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(children: [
                    _buildButton('C', onTap: _clear, color: Colors.grey[300]),
                    _buildButton('⌫', onTap: _backspace, color: Colors.grey[300]),
                    _buildButton('%', onTap: _percent, color: Colors.grey[300]),
                    _buildButton('÷', onTap: () => _operatorClick('÷'), color: Colors.orange[400]),
                  ]),
                  Row(children: [
                    _buildButton('7', onTap: () => _numClick('7')),
                    _buildButton('8', onTap: () => _numClick('8')),
                    _buildButton('9', onTap: () => _numClick('9')),
                    _buildButton('×', onTap: () => _operatorClick('×'), color: Colors.orange[400]),
                  ]),
                  Row(children: [
                    _buildButton('4', onTap: () => _numClick('4')),
                    _buildButton('5', onTap: () => _numClick('5')),
                    _buildButton('6', onTap: () => _numClick('6')),
                    _buildButton('-', onTap: () => _operatorClick('-'), color: Colors.orange[400]),
                  ]),
                  Row(children: [
                    _buildButton('1', onTap: () => _numClick('1')),
                    _buildButton('2', onTap: () => _numClick('2')),
                    _buildButton('3', onTap: () => _numClick('3')),
                    _buildButton('+', onTap: () => _operatorClick('+'), color: Colors.orange[400]),
                  ]),
                  Row(children: [
                    _buildButton('+/-', onTap: _toggleSign, color: Colors.grey[300]),
                    _buildButton('0', onTap: () => _numClick('0')),
                    _buildButton('.', onTap: () => _numClick('.')),
                    _buildButton('=', onTap: _equals, color: Colors.orange[600]),
                  ]),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
