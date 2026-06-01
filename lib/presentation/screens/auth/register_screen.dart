import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/application/register_provider.dart';
import '../../widgets/iot_network_animation.dart';
import 'otp_verification_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _usePhone = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  // Server-side field errors — shown under the relevant field without a snackbar.
  String? _identifierServerError;
  String? _passwordServerError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    // Clear any previous server errors before revalidating.
    setState(() {
      _identifierServerError = null;
      _passwordServerError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    final identifier = _usePhone
        ? _identifierCtrl.text.replaceAll(RegExp(r'[^\+\d]'), '')
        : _identifierCtrl.text.trim();
    ref.read(registerNotifierProvider.notifier).signUp(
          name: _nameCtrl.text.trim(),
          identifier: identifier,
          password: _passwordCtrl.text,
          isPhone: _usePhone,
        );
  }

  void _handleRegisterError(String raw) {
    // Error format: "field:<field>:<message>" for field-level errors,
    // plain string for general snackbar errors.
    if (raw.startsWith('field:identifier:')) {
      setState(() => _identifierServerError = raw.substring(17));
    } else if (raw.startsWith('field:password:')) {
      setState(() => _passwordServerError = raw.substring(15));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(raw),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(registerNotifierProvider);
    final isLoading = state is RegisterLoading;

    ref.listen(registerNotifierProvider, (_, next) {
      if (next is RegisterSuccess && next.requiresConfirmation) {
        ref.read(registerNotifierProvider.notifier).reset();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              username: next.username,
              password: next.password,
              isPhone: next.isPhone,
              displayIdentifier: next.displayIdentifier,
            ),
          ),
        );
      } else if (next is RegisterSuccess && !next.requiresConfirmation) {
        ref.read(registerNotifierProvider.notifier).reset();
      } else if (next is RegisterError) {
        _handleRegisterError(next.message);
        ref.read(registerNotifierProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      resizeToAvoidBottomInset: true,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return _DesktopLayout(
              formKey: _formKey,
              nameCtrl: _nameCtrl,
              identifierCtrl: _identifierCtrl,
              passwordCtrl: _passwordCtrl,
              confirmCtrl: _confirmCtrl,
              usePhone: _usePhone,
              obscurePassword: _obscurePassword,
              obscureConfirm: _obscureConfirm,
              isLoading: isLoading,
              identifierServerError: _identifierServerError,
              passwordServerError: _passwordServerError,
              onToggleIdentifierMode: () => setState(() {
                _usePhone = !_usePhone;
                _identifierCtrl.clear();
                _identifierServerError = null;
              }),
              onIdentifierChanged: (_) {
                if (_identifierServerError != null) {
                  setState(() => _identifierServerError = null);
                }
              },
              onPasswordChanged: (_) {
                if (_passwordServerError != null) {
                  setState(() => _passwordServerError = null);
                }
              },
              onTogglePassword: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              onToggleConfirm: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              onSubmit: _submit,
              onLoginTap: () => Navigator.of(context).pop(),
            );
          }
          return _MobileLayout(
            formKey: _formKey,
            nameCtrl: _nameCtrl,
            identifierCtrl: _identifierCtrl,
            passwordCtrl: _passwordCtrl,
            confirmCtrl: _confirmCtrl,
            usePhone: _usePhone,
            obscurePassword: _obscurePassword,
            obscureConfirm: _obscureConfirm,
            isLoading: isLoading,
            identifierServerError: _identifierServerError,
            passwordServerError: _passwordServerError,
            onToggleIdentifierMode: () => setState(() {
              _usePhone = !_usePhone;
              _identifierCtrl.clear();
              _identifierServerError = null;
            }),
            onIdentifierChanged: (_) {
              if (_identifierServerError != null) {
                setState(() => _identifierServerError = null);
              }
            },
            onPasswordChanged: (_) {
              if (_passwordServerError != null) {
                setState(() => _passwordServerError = null);
              }
            },
            onTogglePassword: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            onToggleConfirm: () =>
                setState(() => _obscureConfirm = !_obscureConfirm),
            onSubmit: _submit,
            onLoginTap: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }
}

// ── Mobile / Tablet ────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.formKey,
    required this.nameCtrl,
    required this.identifierCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.usePhone,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.isLoading,
    required this.onToggleIdentifierMode,
    required this.onIdentifierChanged,
    required this.onPasswordChanged,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onLoginTap,
    this.identifierServerError,
    this.passwordServerError,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController identifierCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool usePhone;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isLoading;
  final String? identifierServerError;
  final String? passwordServerError;
  final VoidCallback onToggleIdentifierMode;
  final void Function(String) onIdentifierChanged;
  final void Function(String) onPasswordChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 50;

    return Stack(
      children: [
        const Positioned.fill(
          child: RepaintBoundary(child: IoTNetworkAnimation()),
        ),
        SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _BackButton(onTap: onLoginTap),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hero section collapses when the keyboard is visible so
                      // the form always has room and never causes overflow.
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 180),
                        crossFadeState: keyboardVisible
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Column(
                          children: [
                            const SizedBox(height: 24),
                            Center(
                              child: Image.asset(
                                'assets/images/logo_no_shadow.png',
                                width: 72,
                                height: 72,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Center(
                              child: Text(
                                'Conectando alertas.\nProtegendo vidas.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondaryDark,
                                  height: 1.55,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.secondary
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Text(
                                  'Sistema de Alarme de Incêndio',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.secondary,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                          ],
                        ),
                        secondChild: const SizedBox(height: 16),
                      ),
                      const Text(
                        'Criar conta',
                        style: AppTextStyles.displayLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Preencha os dados abaixo para começar',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 28),
                      _RegisterForm(
                        formKey: formKey,
                        nameCtrl: nameCtrl,
                        identifierCtrl: identifierCtrl,
                        passwordCtrl: passwordCtrl,
                        confirmCtrl: confirmCtrl,
                        usePhone: usePhone,
                        obscurePassword: obscurePassword,
                        obscureConfirm: obscureConfirm,
                        isLoading: isLoading,
                        identifierServerError: identifierServerError,
                        passwordServerError: passwordServerError,
                        onToggleIdentifierMode: onToggleIdentifierMode,
                        onIdentifierChanged: onIdentifierChanged,
                        onPasswordChanged: onPasswordChanged,
                        onTogglePassword: onTogglePassword,
                        onToggleConfirm: onToggleConfirm,
                        onSubmit: onSubmit,
                        onLoginTap: onLoginTap,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isLoading)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black45,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

// ── Desktop ────────────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
    required this.formKey,
    required this.nameCtrl,
    required this.identifierCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.usePhone,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.isLoading,
    required this.onToggleIdentifierMode,
    required this.onIdentifierChanged,
    required this.onPasswordChanged,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onLoginTap,
    this.identifierServerError,
    this.passwordServerError,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController identifierCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool usePhone;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isLoading;
  final String? identifierServerError;
  final String? passwordServerError;
  final VoidCallback onToggleIdentifierMode;
  final void Function(String) onIdentifierChanged;
  final void Function(String) onPasswordChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 460,
          color: AppColors.backgroundDark,
          child: Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _BackButton(onTap: onLoginTap),
                      ),
                      const SizedBox(height: 40),
                      Image.asset(
                        'assets/images/logo_no_shadow.png',
                        width: 64,
                        height: 64,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Criar conta',
                        style: AppTextStyles.displayLarge,
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Preencha os dados abaixo para começar',
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      _RegisterForm(
                        formKey: formKey,
                        nameCtrl: nameCtrl,
                        identifierCtrl: identifierCtrl,
                        passwordCtrl: passwordCtrl,
                        confirmCtrl: confirmCtrl,
                        usePhone: usePhone,
                        obscurePassword: obscurePassword,
                        obscureConfirm: obscureConfirm,
                        isLoading: isLoading,
                        identifierServerError: identifierServerError,
                        passwordServerError: passwordServerError,
                        onToggleIdentifierMode: onToggleIdentifierMode,
                        onIdentifierChanged: onIdentifierChanged,
                        onPasswordChanged: onPasswordChanged,
                        onTogglePassword: onTogglePassword,
                        onToggleConfirm: onToggleConfirm,
                        onSubmit: onSubmit,
                        onLoginTap: onLoginTap,
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black45,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
            ],
          ),
        ),
        const Expanded(child: _BrandingPane()),
      ],
    );
  }
}

class _BrandingPane extends StatelessWidget {
  const _BrandingPane();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: IoTNetworkAnimation()),
        Container(color: AppColors.backgroundDark.withValues(alpha: 0.45)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/logo_no_shadow.png',
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              const Text(
                'SempreIoT',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Conectando alertas.\nProtegendo vidas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondaryDark,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Sistema de Alarme de Incêndio',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Form ───────────────────────────────────────────────────────────────────

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.formKey,
    required this.nameCtrl,
    required this.identifierCtrl,
    required this.passwordCtrl,
    required this.confirmCtrl,
    required this.usePhone,
    required this.obscurePassword,
    required this.obscureConfirm,
    required this.isLoading,
    required this.onToggleIdentifierMode,
    required this.onIdentifierChanged,
    required this.onPasswordChanged,
    required this.onTogglePassword,
    required this.onToggleConfirm,
    required this.onSubmit,
    required this.onLoginTap,
    this.identifierServerError,
    this.passwordServerError,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController identifierCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController confirmCtrl;
  final bool usePhone;
  final bool obscurePassword;
  final bool obscureConfirm;
  final bool isLoading;
  final String? identifierServerError;
  final String? passwordServerError;
  final VoidCallback onToggleIdentifierMode;
  final void Function(String) onIdentifierChanged;
  final void Function(String) onPasswordChanged;
  final VoidCallback onTogglePassword;
  final VoidCallback onToggleConfirm;
  final VoidCallback onSubmit;
  final VoidCallback onLoginTap;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Field(
            controller: nameCtrl,
            label: 'Nome completo',
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Informe seu nome';
              if (v.trim().length < 2) return 'Nome muito curto';
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Identifier type toggle
          Row(
            children: [
              _ToggleChip(
                label: 'E-mail',
                selected: !usePhone,
                onTap: usePhone ? onToggleIdentifierMode : null,
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Telefone',
                selected: usePhone,
                onTap: !usePhone ? onToggleIdentifierMode : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _Field(
            controller: identifierCtrl,
            label: usePhone ? 'Telefone (ex: +5511999998888)' : 'E-mail',
            // Keep keyboard type consistent across all fields (text) so iOS
            // doesn't dismiss and re-show the keyboard when focus moves between
            // fields with different keyboard types.
            keyboardType: TextInputType.text,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: !usePhone,
            inputFormatters: usePhone
                ? [FilteringTextInputFormatter.allow(RegExp(r'[+\d]'))]
                : null,
            serverError: identifierServerError,
            onChanged: onIdentifierChanged,
            validator: usePhone
                ? (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe seu telefone';
                    }
                    final normalized =
                        v.trim().replaceAll(RegExp(r'[^\+\d]'), '');
                    // Simplified E.164 check: + followed by 8–15 digits
                    if (!RegExp(r'^\+\d{8,15}$').hasMatch(normalized)) {
                      return 'Use o formato internacional: +5511999998888';
                    }
                    return null;
                  }
                : (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Informe seu e-mail';
                    }
                    if (!RegExp(r'^[\w.+\-]+@[a-zA-Z\d\-]+\.[a-zA-Z\d\-.]+$')
                        .hasMatch(v.trim())) {
                      return 'E-mail inválido';
                    }
                    return null;
                  },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: passwordCtrl,
            label: 'Senha',
            keyboardType: TextInputType.text,
            obscureText: obscurePassword,
            textInputAction: TextInputAction.next,
            serverError: passwordServerError,
            onChanged: onPasswordChanged,
            suffix: _VisibilityToggle(
              obscure: obscurePassword,
              onToggle: onTogglePassword,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Informe uma senha';
              if (v.length < 8) return 'Mínimo de 8 caracteres';
              if (!RegExp(r'[A-Z]').hasMatch(v)) {
                return 'Inclua ao menos uma letra maiúscula';
              }
              if (!RegExp(r'[0-9]').hasMatch(v)) {
                return 'Inclua ao menos um número';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: confirmCtrl,
            label: 'Confirmar senha',
            keyboardType: TextInputType.text,
            obscureText: obscureConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => onSubmit(),
            suffix: _VisibilityToggle(
              obscure: obscureConfirm,
              onToggle: onToggleConfirm,
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Confirme sua senha';
              if (v != passwordCtrl.text) return 'As senhas não coincidem';
              return null;
            },
          ),
          const SizedBox(height: 28),
          _SubmitButton(isLoading: isLoading, onPressed: onSubmit),
          const SizedBox(height: 20),
          _LoginLink(onTap: onLoginTap),
        ],
      ),
    );
  }
}

// ── Form widgets ───────────────────────────────────────────────────────────

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.secondary.withValues(alpha: 0.15)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppColors.secondary.withValues(alpha: 0.6)
                : AppColors.divider,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected
                ? AppColors.secondary
                : AppColors.textSecondaryDark,
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.obscureText = false,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.inputFormatters,
    this.serverError,
    this.suffix,
    this.onChanged,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autocorrect;
  final bool enableSuggestions;
  final List<TextInputFormatter>? inputFormatters;
  /// Error text from a server response — shown under the field directly.
  final String? serverError;
  final Widget? suffix;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;

  static InputBorder _border(Color color, {double width = 1.0}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      style: const TextStyle(
        color: AppColors.textPrimaryDark,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      // When a server error is set it takes precedence over the validator.
      // It is cleared as soon as the user edits the field (via onChanged).
      validator: serverError != null ? (_) => serverError : validator,
      autovalidateMode: serverError != null
          ? AutovalidateMode.always
          : AutovalidateMode.disabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: AppColors.textSecondaryDark,
          fontSize: 14,
        ),
        filled: true,
        fillColor: AppColors.surfaceDark,
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: _border(AppColors.divider),
        enabledBorder: _border(AppColors.divider),
        focusedBorder: _border(AppColors.secondary, width: 1.5),
        errorBorder: _border(Colors.red.shade400),
        focusedErrorBorder: _border(Colors.red.shade400, width: 1.5),
        errorStyle: TextStyle(color: Colors.red.shade400, fontSize: 12),
      ),
    );
  }
}

class _VisibilityToggle extends StatelessWidget {
  const _VisibilityToggle({required this.obscure, required this.onToggle});

  final bool obscure;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.textSecondaryDark,
        size: 20,
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.secondary,
          disabledBackgroundColor: AppColors.secondary.withValues(alpha: 0.5),
          foregroundColor: AppColors.backgroundDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.backgroundDark,
                ),
              )
            : const Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _LoginLink extends StatelessWidget {
  const _LoginLink({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: const Text(
          'Já tem uma conta? Entrar',
          style: AppTextStyles.link,
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: 'Voltar',
      icon: const Icon(
        Icons.chevron_left_rounded,
        color: AppColors.textPrimaryDark,
        size: 22,
      ),
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }
}
