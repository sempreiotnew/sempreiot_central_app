import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/central/application/central_auth_provider.dart';

class TopStatusBar extends ConsumerWidget {
  const TopStatusBar({
    super.key,
    required this.isCentral,
    required this.isMobile,
    required this.onMenuToggle,
  });

  final bool isCentral;
  final bool isMobile;
  final VoidCallback onMenuToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).valueOrNull ?? false;

    return Container(
      height: 52,
      decoration: const BoxDecoration(
        color: AppColors.surfaceLow,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _MenuButton(onTap: onMenuToggle),
          const SizedBox(width: 12),
          _AppIdentity(isCentral: isCentral),
          const Spacer(),
          _StatusChip(
            label: 'INTERNET',
            online: isOnline,
            showLabel: !isMobile,
          ),
          const SizedBox(width: 6),
          if (isCentral) ...[
            _StatusChip(
              label: 'USB',
              online: false,
              showLabel: !isMobile,
            ),
            const SizedBox(width: 6),
          ],
          _StatusChip(
            label: 'MQTT',
            online: false,
            showLabel: !isMobile,
          ),
          if (isCentral) ...[
            const SizedBox(width: 10),
            _LockButton(
              onTap: () => ref.read(centralAuthProvider.notifier).reset(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuButton extends StatelessWidget {
  const _MenuButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceMid,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.menu_rounded,
          color: AppColors.textSecondary,
          size: 17,
        ),
      ),
    );
  }
}

class _AppIdentity extends StatelessWidget {
  const _AppIdentity({required this.isCentral});
  final bool isCentral;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.local_fire_department_rounded,
          color: AppColors.accentFire,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'SEMPREIOT',
          style: GoogleFonts.rajdhani(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: 2.5,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isCentral ? AppColors.accentFireDim : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isCentral ? 'CENTRAL' : 'CLIENT',
            style: GoogleFonts.barlow(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isCentral ? AppColors.accentFire : AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatefulWidget {
  const _StatusChip({
    required this.label,
    required this.online,
    required this.showLabel,
  });

  final String label;
  final bool online;
  final bool showLabel;

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor =
        widget.online ? AppColors.statusOnline : AppColors.statusOffline;
    final bgColor =
        widget.online ? AppColors.statusOnlineDim : AppColors.statusOfflineDim;
    final labelColor =
        widget.online ? AppColors.statusOnline : AppColors.statusOffline;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.showLabel ? 8 : 7,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) => Opacity(
              opacity: widget.online ? 1.0 : _pulseAnim.value,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          if (widget.showLabel) ...[
            const SizedBox(width: 5),
            Text(
              widget.label,
              style: GoogleFonts.barlow(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LockButton extends StatelessWidget {
  const _LockButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.surfaceMid,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.lock_outline_rounded,
          color: AppColors.textSecondary,
          size: 16,
        ),
      ),
    );
  }
}
