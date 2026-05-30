import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final bool dark;

  const PremiumBackground({
    super.key,
    required this.child,
    this.colors,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = colors ?? (dark
        ? const [Color(0xFF081226), Color(0xFF111C3A), Color(0xFF1F1147)]
        : const [Color(0xFFF7F8FF), Color(0xFFF0F9FF), Color(0xFFEEF2FF)]);
    return Stack(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
          ),
          child: const SizedBox.expand(),
        ),
        Positioned(
          top: -80,
          left: -30,
          child: _GlowOrb(color: AppColors.primary.withAlpha(dark ? 70 : 45), size: 220),
        ),
        Positioned(
          top: 120,
          right: -70,
          child: _GlowOrb(color: AppColors.accent.withAlpha(dark ? 60 : 35), size: 200),
        ),
        Positioned(
          bottom: -90,
          left: 40,
          child: _GlowOrb(color: AppColors.superBlue.withAlpha(dark ? 60 : 30), size: 240),
        ),
        child,
      ],
    );
  }
}

class PremiumScrollScaffold extends StatelessWidget {
  final Widget child;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;
  final bool safeTop;

  const PremiumScrollScaffold({
    super.key,
    required this.child,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.safeTop = true,
  });

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(top: safeTop, bottom: false, child: child);
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.transparent,
      extendBodyBehindAppBar: true,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      body: PremiumBackground(child: body),
    );
  }
}

class PremiumGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final List<Color>? gradient;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const PremiumGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.gradient,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.xl);
    final content = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient != null
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradient!,
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withAlpha(225),
                      Colors.white.withAlpha(165),
                    ],
                  ),
            borderRadius: radius,
            border: Border.all(color: Colors.white.withAlpha(140)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(18),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
    if (onTap == null) return content;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap?.call();
      },
      child: content,
    );
  }
}

class PremiumHeroHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color>? gradient;
  final Widget? trailing;
  final List<Widget>? chips;

  const PremiumHeroHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.gradient,
    this.trailing,
    this.chips,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.huge, AppSpacing.lg, AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient ?? const [AppColors.primary, AppColors.accent],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        boxShadow: AppShadows.lg((gradient ?? AppColors.primaryGradient).first),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(28),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: Colors.white.withAlpha(40)),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.7,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withAlpha(225),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (chips != null && chips!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(spacing: 8, runSpacing: 8, children: chips!),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class PremiumStatChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const PremiumStatChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: Colors.white.withAlpha(50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const PremiumSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final List<Color>? gradient;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: PremiumGlassCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient ?? const [AppColors.primary, AppColors.accent]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(icon, color: Colors.white, size: 42),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: AppSpacing.sm),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.xl),
                PremiumGradientButton(label: actionLabel!, onPressed: onAction!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PremiumGradientButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final List<Color>? colors;
  final EdgeInsetsGeometry? padding;

  const PremiumGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.colors,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onPressed();
      },
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors ?? const [AppColors.primary, AppColors.accent]),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: AppShadows.md((colors ?? AppColors.primaryGradient).first),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class PremiumLoadingList extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const PremiumLoadingList({
    super.key,
    this.itemCount = 4,
    this.itemHeight = 110,
  });

  @override
  State<PremiumLoadingList> createState() => _PremiumLoadingListState();
}

class _PremiumLoadingListState extends State<PremiumLoadingList> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final shimmer = (math.sin(_controller.value * math.pi * 2) + 1) / 2;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemBuilder: (_, __) => Container(
            height: widget.itemHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              gradient: LinearGradient(
                begin: Alignment(-1 + shimmer * 2, -1),
                end: Alignment(1 + shimmer * 2, 1),
                colors: const [Color(0xFFE8ECFF), Color(0xFFF6F8FF), Color(0xFFE8ECFF)],
              ),
            ),
          ),
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
          itemCount: widget.itemCount,
        );
      },
    );
  }
}

class PremiumStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const PremiumStatusPill({
    super.key,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

class PremiumMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const PremiumMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withAlpha(18),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Color>? gradient;
  final List<Widget>? actions;
  final bool dark;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.gradient,
    this.actions,
    this.dark = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        title,
        style: TextStyle(
          color: dark ? Colors.white : AppColors.surfaceDark,
          fontWeight: FontWeight.w800,
        ),
      ),
      centerTitle: false,
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient ?? (dark ? const [Color(0xFF111827), Color(0xFF0F172A)] : const [Color(0xFFF9FAFF), Color(0xFFF2F6FF)]),
          ),
        ),
      ),
    );
  }
}

class PremiumSearchField extends StatelessWidget {
  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;

  const PremiumSearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.suffix,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onTap: onTap,
        readOnly: readOnly,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded, color: AppColors.primary),
          hintText: hint,
          suffixIcon: suffix,
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    );
  }
}
