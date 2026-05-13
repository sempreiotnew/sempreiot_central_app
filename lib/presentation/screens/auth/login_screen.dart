import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sempreiot_central_app/presentation/widgets/iot_network_animation.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/application/auth_provider.dart';
import 'register_screen.dart';

void _showSempreIoTLoginModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _SempreIoTLoginModal(),
  );
}

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          const Positioned.fill(child: IoTNetworkAnimation()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(flex: 2),
                  const _Logo(),
                  const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  const Spacer(flex: 2),
                  const Text(
                    'Escolha como deseja entrar',
                    style: AppTextStyles.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  _SempreIoTButton(
                    onTap: isLoading
                        ? null
                        : () => _showSempreIoTLoginModal(context),
                  ),
                  const SizedBox(height: 16),
                  _SocialButton(
                    onTap: isLoading
                        ? null
                        : () => ref
                            .read(authNotifierProvider.notifier)
                            .signInWithGoogle(),
                    icon: const _GoogleIcon(),
                    label: 'Continuar com Google',
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.textPrimaryLight,
                  ),
                  if (kIsWeb ||
                      defaultTargetPlatform != TargetPlatform.android) ...[
                    const SizedBox(height: 16),
                    _SocialButton(
                      onTap: isLoading
                          ? null
                          : () => ref
                              .read(authNotifierProvider.notifier)
                              .signInWithApple(),
                      icon: const Icon(
                        Icons.apple,
                        color: AppColors.white,
                        size: 28,
                      ),
                      label: 'Continuar com Apple',
                      backgroundColor: AppColors.black,
                      foregroundColor: AppColors.white,
                      border: Border.all(color: AppColors.divider),
                    ),
                  ],
                  const Spacer(flex: 1),
                  const _Divider(),
                  const SizedBox(height: 24),
                  _RegisterButton(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
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
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/google_icon.png',
      width: 22,
      height: 22,
      fit: BoxFit.contain,
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logo_no_shadow.png',
      width: 160,
      height: 160,
      fit: BoxFit.contain,
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onTap,
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.border,
  });

  final VoidCallback? onTap;
  final Widget icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.6 : 1.0,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: border,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                icon,
                const SizedBox(width: 12),
                Text(
                  label,
                  style:
                      AppTextStyles.labelLarge.copyWith(color: foregroundColor),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        SizedBox(width: 16),
        Text('ou', style: AppTextStyles.bodyMedium),
        SizedBox(width: 16),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }
}

class _RegisterButton extends StatelessWidget {
  const _RegisterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.secondary),
          ),
          child: const Center(
            child: Text('Criar uma conta', style: AppTextStyles.labelLarge),
          ),
        ),
      ),
    );
  }
}

class _SempreIoTButton extends StatelessWidget {
  const _SempreIoTButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.6 : 1.0,
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF1A4A8A)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo_no_shadow.png',
                  width: 26,
                  height: 26,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Text(
                  'Continuar com Sempre IoT',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SempreIoTLoginModal extends ConsumerStatefulWidget {
  const _SempreIoTLoginModal();

  @override
  ConsumerState<_SempreIoTLoginModal> createState() =>
      _SempreIoTLoginModalState();
}

class _SempreIoTLoginModalState extends ConsumerState<_SempreIoTLoginModal> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref.read(authNotifierProvider.notifier).signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
    if (mounted && !ref.read(authNotifierProvider).hasError) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    ref.listen(authNotifierProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    });

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Image.asset(
                    'assets/images/logo_no_shadow.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Entrar com Sempre IoT',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimaryLight,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.textPrimaryLight),
                decoration: _inputDecoration(
                  label: 'E-mail',
                  icon: Icons.email_outlined,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                  if (!v.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                style: const TextStyle(color: AppColors.textPrimaryLight),
                decoration: _inputDecoration(
                  label: 'Senha',
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.textSecondaryLight,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a senha';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: isLoading ? null : _submit,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, Color(0xFF1A4A8A)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Entrar',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondaryLight),
      prefixIcon: Icon(icon, color: AppColors.textSecondaryLight, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceLight,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
