import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// Custom page route with slide + fade transition.
class AppPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppPageRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: AppDurations.pageTransition,
          reverseTransitionDuration: AppDurations.normal,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween<Offset>(
              begin: const Offset(0.08, 0),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            final fadeTween = Tween<double>(begin: 0.0, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOut));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Bottom-to-top slide route (for modals/sheets).
class AppBottomSheetRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppBottomSheetRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: AppDurations.normal,
          reverseTransitionDuration: AppDurations.fast,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween = Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutCubic));

            return SlideTransition(
              position: animation.drive(slideTween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}

/// Scale transition for success/confirmation screens.
class AppScaleRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  AppScaleRoute({required this.page})
      : super(
          pageBuilder: (_, __, ___) => page,
          transitionDuration: AppDurations.slow,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final scaleTween = Tween<double>(begin: 0.9, end: 1.0)
                .chain(CurveTween(curve: Curves.easeOutBack));

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            );
          },
        );
}
