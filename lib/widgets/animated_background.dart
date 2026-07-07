import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Simplified background — flat solid color, with a subtle
/// accent-tinted overlay when in alert mode. No animated gradient blobs.
class AnimatedBackground extends StatefulWidget {
  final Widget child;
  final bool isAlert;

  const AnimatedBackground({
    super.key,
    required this.child,
    this.isAlert = false,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _alertPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _alertPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Flat solid background
        Container(
          color: widget.isAlert
              ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A0A0A) : const Color(0xFFFFF0F0))
              : Theme.of(context).scaffoldBackgroundColor,
        ),

        // Alert pulse overlay (only when SOS is active)
        if (widget.isAlert)
          AnimatedBuilder(
            animation: _alertPulse,
            builder: (context, child) {
              return Container(
                color: AppTheme.sosRed.withValues(
                  alpha: 0.04 + (_alertPulse.value * 0.06),
                ),
              );
            },
          ),

        // Child content
        widget.child,
      ],
    );
  }
}

/// Kept for API compat — no longer renders.
class MovingBlob extends StatelessWidget {
  final Color color;
  final double size;
  final Offset offset;

  const MovingBlob({
    super.key,
    required this.color,
    required this.size,
    required this.offset,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
