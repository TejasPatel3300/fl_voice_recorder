import 'package:flutter/material.dart';

class RippleAnimation extends StatefulWidget {
  final Widget child;
  final bool animate;

  const RippleAnimation({super.key, required this.child, this.animate = false});

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(seconds: 2), vsync: this)..repeat();
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
      builder: (_, child) {
        final scale = 1 + _controller.value * 1.5;
        final opacity = (1 - _controller.value).clamp(0.0, 1.0);

        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.animate)
              Container(
                width: 140 * scale,
                height: 140 * scale,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1 * opacity),
                ),
              ),
            child!,
          ],
        );
      },
      child: widget.child,
    );
  }
}
