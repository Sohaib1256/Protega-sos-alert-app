import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onTrigger;
  final bool isActive;

  const SOSButton({
    super.key,
    required this.onTrigger,
    this.isActive = false,
  });

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  bool _isHolding = false;
  double _holdProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addListener(() {
      setState(() {
        _holdProgress = _controller.value;
      });
    });

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onTrigger();
        _controller.reset();
        setState(() {
          _isHolding = false;
          _holdProgress = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHoldStart() {
    setState(() => _isHolding = true);
    _controller.forward();
    HapticFeedback.mediumImpact();
  }

  void _onHoldEnd() {
    setState(() {
      _isHolding = false;
      _holdProgress = 0.0;
    });
    _controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => _onHoldStart(),
      onLongPressEnd: (_) => _onHoldEnd(),
      onLongPressCancel: () => _onHoldEnd(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Ripple effect when holding
              if (_isHolding)
                Container(
                  width: 220 + (80 * _rippleAnimation.value),
                  height: 220 + (80 * _rippleAnimation.value),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.sosRed.withValues(alpha: 1 - _rippleAnimation.value),
                      width: 2,
                    ),
                  ),
                ),

              // Main SOS button — solid, tactile hardware look
              Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isHolding
                        ? const Color(0xFFCF2D3A)
                        : AppTheme.sosRed,
                    boxShadow: [
                      // Subtle outer drop shadow
                      BoxShadow(
                        color: AppTheme.sosRed.withValues(alpha: 0.25),
                        blurRadius: 16,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                      // Inner bevel highlight (top-left)
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.12),
                        blurRadius: 1,
                        spreadRadius: -1,
                        offset: const Offset(-2, -2),
                      ),
                      // Inner bevel shadow (bottom-right)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 4,
                        spreadRadius: -2,
                        offset: const Offset(3, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Progress ring
                      if (_isHolding)
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: _holdProgress,
                            strokeWidth: 5,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            backgroundColor: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),

                      // Content — clean bold "SOS" text, no icon
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'SOS',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _isHolding
                                ? 'Hold ${(_holdProgress * 100).toInt()}%'
                                : 'Hold for Emergency',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
