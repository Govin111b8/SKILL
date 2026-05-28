import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Beautiful illustrated empty states with animated elements.
/// Replaces plain text with engaging visuals and clear CTAs.
class IllustratedEmptyState extends StatefulWidget {
  final String illustration; // emoji
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? accentColor;

  const IllustratedEmptyState({
    super.key,
    required this.illustration,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.accentColor,
  });

  // Predefined empty states
  factory IllustratedEmptyState.noBookings({VoidCallback? onAction}) => IllustratedEmptyState(
    illustration: '📋',
    title: 'No bookings yet',
    subtitle: 'Your booking history will appear here.\nFind a professional to get started!',
    actionLabel: 'Browse Services',
    onAction: onAction,
    accentColor: AppColors.primary,
  );

  factory IllustratedEmptyState.noMessages() => const IllustratedEmptyState(
    illustration: '💬',
    title: 'No messages',
    subtitle: 'Start a conversation by booking\na service or contacting a professional.',
    accentColor: AppColors.info,
  );

  factory IllustratedEmptyState.noResults() => const IllustratedEmptyState(
    illustration: '🔍',
    title: 'No results found',
    subtitle: 'Try different keywords or\nbroaden your search filters.',
    accentColor: AppColors.warning,
  );

  factory IllustratedEmptyState.noFavorites({VoidCallback? onAction}) => IllustratedEmptyState(
    illustration: '❤️',
    title: 'No favorites yet',
    subtitle: 'Save your favorite professionals\nfor quick access later.',
    actionLabel: 'Explore',
    onAction: onAction,
    accentColor: AppColors.error,
  );

  factory IllustratedEmptyState.noNotifications() => const IllustratedEmptyState(
    illustration: '🔔',
    title: 'All caught up!',
    subtitle: 'You\'ll see booking updates,\nmessages, and offers here.',
    accentColor: AppColors.secondary,
  );

  @override
  State<IllustratedEmptyState> createState() => _IllustratedEmptyStateState();
}

class _IllustratedEmptyStateState extends State<IllustratedEmptyState> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: 8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl, vertical: AppSpacing.huge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated illustration
            AnimatedBuilder(
              animation: _bounce,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -_bounce.value),
                child: child,
              ),
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: color.withAlpha(15),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withAlpha(40), width: 2),
                ),
                child: Center(
                  child: Text(widget.illustration, style: const TextStyle(fontSize: 44)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500, height: 1.5),
              textAlign: TextAlign.center,
            ),
            if (widget.actionLabel != null && widget.onAction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              ElevatedButton.icon(
                onPressed: widget.onAction,
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(widget.actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
