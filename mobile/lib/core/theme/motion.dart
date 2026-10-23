import 'package:flutter/material.dart';

/// Quiet transitions shared by Material routes on mobile and desktop.
class HopelyPageTransitions extends PageTransitionsBuilder {
  const HopelyPageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context) || route.isFirst) return child;
    final progress = animation.drive(
      CurveTween(curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: progress,
      child: SlideTransition(
        position: progress.drive(
          Tween<Offset>(begin: const Offset(0, 0.015), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }
}
