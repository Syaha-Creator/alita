import 'package:flutter/material.dart';

/// Lightweight press animation without changing layout structure.
class TapScale extends StatefulWidget {
  const TapScale({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 120),
    this.pressedScale = 0.98,
  });

  final Widget child;
  final Duration duration;
  final double pressedScale;

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        scale: _pressed ? widget.pressedScale : 1,
        child: widget.child,
      ),
    );
  }
}
