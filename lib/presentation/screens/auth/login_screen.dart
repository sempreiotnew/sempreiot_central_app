import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sempreiot_central_app/presentation/widgets/iot_network_animation.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../features/auth/application/auth_provider.dart';

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
                  _RegisterButton(onTap: () {}),
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
