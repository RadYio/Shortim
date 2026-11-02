import 'package:flutter/material.dart';

import '../theme.dart';

/// Page route that fades the new screen in while it slides up slightly,
/// instead of the default Material push.
Route<T> fadeSlideRoute<T>(WidgetBuilder builder) => PageRouteBuilder<T>(
  transitionDuration: AppMotion.slow,
  reverseTransitionDuration: AppMotion.base,
  pageBuilder: (context, _, _) => builder(context),
  transitionsBuilder: (context, animation, _, child) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.brand,
      reverseCurve: AppMotion.brand.flipped,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  },
);
