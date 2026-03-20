import 'package:flutter/material.dart';

/// Wraps a child with a subtle fade + slide-up entrance animation.
///
/// Use inside `itemBuilder` of `ListView.builder` or `SliverMasonryGrid`.
/// The [index] controls stagger delay so items animate in sequence.
///
/// ```dart
/// AnimatedListItem(
///   index: index,
///   child: ProductCard(...),
/// )
/// ```
class AnimatedListItem extends StatefulWidget {
  final int index;
  final Widget child;
  final Duration duration;

  /// Maximum stagger offset so items far down the list don't wait too long.
  final int maxStaggerIndex;

  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.maxStaggerIndex = 10,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final stagger = widget.index.clamp(0, widget.maxStaggerIndex);
    Future.delayed(Duration(milliseconds: stagger * 50), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: widget.child,
      ),
    );
  }
}
