import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../application/device_metadata_providers.dart';
import '../../../../shared/widgets/pin_pad.dart';

enum _PinStep { current, newPin, confirm }

extension on _PinStep {
  String get title => switch (this) {
        _PinStep.current => 'Digite o PIN atual',
        _PinStep.newPin  => 'Digite o novo PIN',
        _PinStep.confirm => 'Confirme o novo PIN',
      };
}

class PinChangeScreen extends ConsumerStatefulWidget {
  const PinChangeScreen({super.key});

  @override
  ConsumerState<PinChangeScreen> createState() => _PinChangeScreenState();
}

class _PinChangeScreenState extends ConsumerState<PinChangeScreen> {
  _PinStep _step = _PinStep.current;
  final List<String> _digits = [];
  String _newPinValue = '';
  String? _errorMessage;
  bool _busy = false;

  // ── Input handlers ────────────────────────────────────────────────────────

  void _onDigit(String d) {
    if (_digits.length >= 6 || _busy) return;
    setState(() {
      _digits.add(d);
      _errorMessage = null;
    });
    if (_digits.length == 6) _onComplete();
  }

  void _onDelete() {
    if (_digits.isEmpty || _busy) return;
    setState(() {
      _digits.removeLast();
      _errorMessage = null;
    });
  }

  void _clearWithError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _digits.clear());
    });
  }

  // ── Step completion ───────────────────────────────────────────────────────

  Future<void> _onComplete() async {
    final entered = _digits.join();

    switch (_step) {
      case _PinStep.current:
        await _validateCurrentPin(entered);
      case _PinStep.newPin:
        _advanceToConfirm(entered);
      case _PinStep.confirm:
        await _confirmAndSave(entered);
    }
  }

  Future<void> _validateCurrentPin(String entered) async {
    setState(() => _busy = true);
    final db = ref.read(appDatabaseProvider);

    try {
      final raw = await db.getMeta('credentials');
      String storedPin = '';
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        storedPin = map['pin'] as String? ?? '';
      }

      if (storedPin.isEmpty) {
        if (mounted) {
          _clearWithError('PIN não configurado.');
          setState(() => _busy = false);
        }
        return;
      }

      if (entered == storedPin) {
        if (mounted) {
          setState(() {
            _step = _PinStep.newPin;
            _digits.clear();
            _errorMessage = null;
            _busy = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _busy = false);
          _clearWithError('PIN incorreto. Tente novamente.');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _clearWithError('Erro ao verificar PIN.');
      }
    }
  }

  void _advanceToConfirm(String entered) {
    setState(() {
      _newPinValue = entered;
      _step = _PinStep.confirm;
      _digits.clear();
      _errorMessage = null;
    });
  }

  Future<void> _confirmAndSave(String entered) async {
    if (entered != _newPinValue) {
      setState(() {
        _step = _PinStep.newPin;
        _newPinValue = '';
        _digits.clear();
      });
      _clearWithError('PINs não coincidem. Tente novamente.');
      return;
    }

    setState(() => _busy = true);
    final db = ref.read(appDatabaseProvider);

    try {
      final raw = await db.getMeta('credentials');
      final map = raw != null && raw.isNotEmpty
          ? jsonDecode(raw) as Map<String, dynamic>
          : <String, dynamic>{};
      map['pin'] = entered;
      await db.setMeta('credentials', jsonEncode(map));
      ref.invalidate(deviceCredentialsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN alterado com sucesso.'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        _clearWithError('Erro ao salvar PIN.');
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final hasError = _errorMessage != null;

    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          'Alterar PIN',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Divider(
            height: 0.5,
            thickness: 0.5,
            color: context.borderColor.withValues(alpha: 0.5),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 12),

                  // Step indicator
                  _StepIndicator(current: _step),
                  const SizedBox(height: 32),

                  // Title
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _step.title,
                      key: ValueKey(_step),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // PIN dots
                  PinDots(
                    filledCount: _digits.length,
                    hasError: hasError,
                  ),
                  const SizedBox(height: 14),

                  // Error label
                  AnimatedOpacity(
                    opacity: hasError ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      _errorMessage ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Numpad
                  AnimatedOpacity(
                    opacity: _busy ? 0.4 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: PinPad(
                      onDigit: _onDigit,
                      onDelete: _onDelete,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Step indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});
  final _PinStep current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _PinStep.values.map((step) {
        final done = step.index < current.index;
        final active = step == current;
        final color = (done || active) ? AppColors.secondary : context.borderColor;

        return Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: active ? 28 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            if (step != _PinStep.values.last)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 12,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: done
                    ? AppColors.secondary.withValues(alpha: 0.5)
                    : context.borderColor.withValues(alpha: 0.4),
              ),
          ],
        );
      }).toList(),
    );
  }
}
