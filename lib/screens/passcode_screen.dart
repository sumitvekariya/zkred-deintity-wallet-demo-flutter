import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/passcode_provider.dart';
import '../theme/app_theme.dart';

class PasscodeScreen extends StatefulWidget {
  const PasscodeScreen({super.key});

  @override
  State<PasscodeScreen> createState() => _PasscodeScreenState();
}

enum _PasscodeMode { create, confirm, verify }

class _PasscodeScreenState extends State<PasscodeScreen>
    with SingleTickerProviderStateMixin {
  static const _length = 6;

  String _input = '';
  String _firstEntry = '';
  _PasscodeMode _mode = _PasscodeMode.verify;
  String? _errorMessage;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim =
        Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    final passcode = context.read<PasscodeProvider>();
    await passcode.checkPasscode();
    if (!mounted) return;
    setState(() {
      _mode =
          passcode.hasPasscode ? _PasscodeMode.verify : _PasscodeMode.create;
      _checked = true;
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _addDigit(String d) async {
    if (_input.length >= _length) return;
    setState(() {
      _input = _input + d;
      _errorMessage = null;
    });
    if (_input.length == _length) {
      await _onComplete();
    }
  }

  void _backspace() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _onComplete() async {
    final passcode = context.read<PasscodeProvider>();
    switch (_mode) {
      case _PasscodeMode.create:
        setState(() {
          _firstEntry = _input;
          _input = '';
          _mode = _PasscodeMode.confirm;
        });
        break;
      case _PasscodeMode.confirm:
        if (_input == _firstEntry) {
          await passcode.save(_input);
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _shake();
          setState(() {
            _input = '';
            _firstEntry = '';
            _mode = _PasscodeMode.create;
            _errorMessage = 'Passcodes did not match. Try again.';
          });
        }
        break;
      case _PasscodeMode.verify:
        final ok = await passcode.verify(_input);
        if (!mounted) return;
        if (ok) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          _shake();
          setState(() {
            _input = '';
            _errorMessage = 'Incorrect passcode';
          });
        }
        break;
    }
  }

  void _shake() {
    _shakeCtrl.forward(from: 0);
  }

  String get _title {
    switch (_mode) {
      case _PasscodeMode.create:
        return 'Create your passcode';
      case _PasscodeMode.confirm:
        return 'Confirm your passcode';
      case _PasscodeMode.verify:
        return 'Enter your passcode';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case _PasscodeMode.create:
        return 'This 6-digit code unlocks your wallet';
      case _PasscodeMode.confirm:
        return 'Re-enter the same 6 digits';
      case _PasscodeMode.verify:
        return 'Welcome back';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: !_checked
              ? const Center(
                  child: CircularProgressIndicator(color: ZKColors.primary))
              : Column(
                  children: [
                    const SizedBox(height: 60),
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: ZKColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: ZKColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (context, child) {
                        final dx =
                            math.sin(_shakeAnim.value * math.pi * 6) * 10;
                        return Transform.translate(
                          offset: Offset(dx, 0),
                          child: child,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_length, (i) {
                          final filled = i < _input.length;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: filled
                                  ? ZKColors.primary
                                  : Colors.transparent,
                              border: Border.all(
                                color: ZKColors.textSecondary,
                                width: 1.6,
                              ),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 20,
                      child: _errorMessage != null
                          ? Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: ZKColors.error,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                    const Spacer(),
                    _Keypad(
                      onDigit: _addDigit,
                      onBackspace: _backspace,
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['*', '0', '<'],
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                if (key == '<') {
                  return _KeyButton(
                    onTap: onBackspace,
                    child: const Icon(
                      Icons.backspace_outlined,
                      color: ZKColors.shield,
                    ),
                  );
                }
                if (key == '*') {
                  return const SizedBox(width: 70, height: 70);
                }
                return _KeyButton(
                  onTap: () => onDigit(key),
                  child: Text(
                    key,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: ZKColors.trust,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  const _KeyButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 40,
      child: Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.06),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
