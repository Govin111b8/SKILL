import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_tokens.dart';

/// Branded pull-to-refresh indicator matching SkillConnect colors.
class BrandedRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  const BrandedRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      strokeWidth: 2.5,
      displacement: 50,
      child: child,
    );
  }
}

/// Shimmer loading that transitions to content with a fade-in animation.
/// Wraps a child: when [loading] is true, shows shimmer; when false, fades in content.
class ShimmerToContent extends StatelessWidget {
  final bool loading;
  final Widget shimmer;
  final Widget content;

  const ShimmerToContent({
    super.key,
    required this.loading,
    required this.shimmer,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.normal,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: loading
          ? KeyedSubtree(key: const ValueKey('shimmer'), child: shimmer)
          : KeyedSubtree(key: const ValueKey('content'), child: content),
    );
  }
}

/// Standard haptic feedback helper — standardizes haptic usage across the app.
class AppHaptics {
  AppHaptics._();

  /// Light tap — for selection changes, toggles.
  static void tap() => HapticFeedback.selectionClick();

  /// Medium — for button presses, confirmations.
  static void press() => HapticFeedback.mediumImpact();

  /// Heavy — for success states, important actions.
  static void success() => HapticFeedback.heavyImpact();

  /// Light — for minor interactions (scroll snap, hover feedback).
  static void light() => HapticFeedback.lightImpact();
}
