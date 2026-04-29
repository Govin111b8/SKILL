import 'package:flutter/material.dart';

/// Animated shimmer skeleton loader — no external package required.
/// Usage: Wrap [SkeletonBox] or [SkeletonCard] inside a [SkeletonShimmer].
class SkeletonShimmer extends StatefulWidget {
  final Widget child;
  const SkeletonShimmer({super.key, required this.child});

  @override
  State<SkeletonShimmer> createState() => _SkeletonShimmerState();
}

class _SkeletonShimmerState extends State<SkeletonShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(-1.5 + _anim.value * 3, 0),
          end:   Alignment(-0.5 + _anim.value * 3, 0),
          colors: Theme.of(context).brightness == Brightness.dark
              ? [const Color(0xFF1E293B), const Color(0xFF334155), const Color(0xFF1E293B)]
              : [const Color(0xFFE2E8F0), const Color(0xFFF8FAFC), const Color(0xFFE2E8F0)],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// A single placeholder box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 8});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF1E293B)
        : const Color(0xFFE2E8F0);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(radius)),
    );
  }
}

/// Skeleton for a professional card
class SkeletonProfessionalCard extends StatelessWidget {
  const SkeletonProfessionalCard({super.key});

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    return SkeletonShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const SkeletonBox(width: 56, height: 56, radius: 16),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SkeletonBox(width: 140, height: 14),
                const SizedBox(height: 8),
                const SkeletonBox(width: 100, height: 11),
                const SizedBox(height: 8),
                Row(children: [
                  const SkeletonBox(width: 60, height: 10),
                  const SizedBox(width: 8),
                  const SkeletonBox(width: 50, height: 10),
                ]),
              ]),
            ),
            const SizedBox(width: 12),
            const SkeletonBox(width: 60, height: 28, radius: 20),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for a booking card
class SkeletonBookingCard extends StatelessWidget {
  const SkeletonBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    return SkeletonShimmer(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const SkeletonBox(width: 40, height: 40, radius: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              SkeletonBox(width: 130, height: 13),
              SizedBox(height: 6),
              SkeletonBox(width: 80, height: 10),
            ])),
            const SkeletonBox(width: 70, height: 26, radius: 20),
          ]),
          const SizedBox(height: 12),
          const SkeletonBox(height: 14, radius: 8),
          const SizedBox(height: 8),
          const SkeletonBox(width: 220, height: 11, radius: 8),
          const SizedBox(height: 10),
          Row(children: const [
            SkeletonBox(width: 100, height: 10),
            Spacer(),
            SkeletonBox(width: 50, height: 14),
          ]),
        ]),
      ),
    );
  }
}

/// Skeleton for a notification item
class SkeletonNotificationTile extends StatelessWidget {
  const SkeletonNotificationTile({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          const SkeletonBox(width: 44, height: 44, radius: 22),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            SkeletonBox(width: 160, height: 13),
            SizedBox(height: 6),
            SkeletonBox(width: 220, height: 10),
            SizedBox(height: 4),
            SkeletonBox(width: 70, height: 9),
          ])),
        ]),
      ),
    );
  }
}

/// A generic empty-state widget with icon, title, subtitle, and optional action
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? illustration;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = iconColor ?? cs.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(icon, size: 48, color: color.withAlpha(180)),
            ),
            const SizedBox(height: 24),
            Text(title, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
