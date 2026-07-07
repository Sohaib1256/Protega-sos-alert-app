import 'package:flutter/material.dart';

/// A simple surface card with a subtle border — no glassmorphism.
/// Drop-in replacement for the old GlassCard.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? color;
  final double blur; // kept for API compat, ignored
  final VoidCallback? onTap;
  final Border? border;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.color,
    this.blur = 16.0,
    this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(16);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: effectiveBorderRadius,
        border: border ??
            Border.all(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
      ),
      child: child,
    );

    if (margin != null) {
      content = Padding(
        padding: margin!,
        child: content,
      );
    }

    if (onTap != null) {
      content = GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}

/// Simplified container — no blur, no glass.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16.0,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Theme.of(context).dividerColor,
        ),
      ),
      child: child,
    );
  }
}
