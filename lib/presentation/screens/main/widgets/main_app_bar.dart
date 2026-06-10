import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_ext.dart';
import '../../../../features/auth/application/auth_provider.dart';
import '../../../../features/central/application/central_auth_provider.dart';
import 'status_indicators.dart';

class MainAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    required this.onMenuTap,
    this.isLocked = false,
  });

  final VoidCallback? onMenuTap;
  final bool isLocked;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      height: preferredSize.height + topPad,
      padding: EdgeInsets.only(top: topPad),
      decoration: BoxDecoration(
        color: context.bgColor,
        border: Border(
          bottom: BorderSide(
            color: context.borderColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (!isLocked) ...[
              _BarIconButton(
                icon: Icons.menu_rounded,
                onTap: onMenuTap ?? () {},
                tooltip: 'Menu',
              ),
              const SizedBox(width: 6),
            ] else
              const SizedBox(width: 12),
            const Expanded(child: _Branding()),
            const WifiIndicator(),
            if (AppConfig.isCentral) ...[
              const SizedBox(width: 2),
              const UsbIndicator(),
            ],
            const SizedBox(width: 2),
            MqttIndicator(disabled: AppConfig.isCentral),
            if (AppConfig.isCentral && !isLocked) ...[
              const SizedBox(width: 2),
              _LockButton(
                onTap: () => ref.read(centralAuthProvider.notifier).reset(),
              ),
            ],
            if (isLocked) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: 'Toque na tela para desbloquear',
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.lock_rounded,
                    color: context.textSecondary.withValues(alpha: 0.5),
                    size: 18,
                  ),
                ),
              ),
            ],
            if (!isLocked) ...[
              const SizedBox(width: 10),
              const _UserAvatar(),
            ],
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _Branding extends StatelessWidget {
  const _Branding();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.secondary],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.sensors_rounded,
            color: AppColors.white,
            size: 15,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConfig.isCentral ? 'Central' : 'SempreIoT',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            Text(
              AppConfig.isCentral ? 'Modo Central' : 'Painel de controle',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: context.textSecondary, size: 22),
          ),
        ),
      ),
    );
  }
}

class _LockButton extends StatelessWidget {
  const _LockButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Bloquear Central',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.lock_outline_rounded,
              color: context.textSecondary,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends ConsumerWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initials = AppConfig.isCentral
        ? 'CT'
        : _initials(ref.watch(authNotifierProvider).valueOrNull?.userId ?? '');

    return GestureDetector(
      onTap: () => _showProfile(context, ref, initials),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, Color(0xFF2E6DA4)],
          ),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  String _initials(String userId) {
    final clean = userId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.isEmpty) return '?';
    return clean.substring(0, clean.length.clamp(0, 2)).toUpperCase();
  }

  void _showProfile(BuildContext context, WidgetRef ref, String initials) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _ProfileSheet(initials: initials),
      ),
    );
  }
}

class _ProfileSheet extends ConsumerWidget {
  const _ProfileSheet({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = AppConfig.isCentral
        ? 'Modo Central'
        : (ref.watch(authNotifierProvider).valueOrNull?.userId ?? '—');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _AvatarCircle(initials: initials, size: 64, fontSize: 22),
          const SizedBox(height: 16),
          Text(
            AppConfig.isCentral ? 'Central SempreIoT' : 'Minha conta',
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userId,
            style: TextStyle(color: context.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 28),
          if (!AppConfig.isCentral)
            _ActionButton(
              icon: Icons.logout_rounded,
              label: 'Sair da conta',
              color: AppColors.error,
              onTap: () {
                Navigator.pop(context);
                ref.read(authNotifierProvider.notifier).signOut();
              },
            ),
        ],
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({
    required this.initials,
    required this.size,
    required this.fontSize,
  });

  final String initials;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFF2E6DA4)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: AppColors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
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
