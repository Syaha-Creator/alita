import 'package:flutter/material.dart';
import 'section_card.dart';

/// Shared card surface style used in detail pages.
class DetailSurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const DetailSurfaceCard({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: padding ?? const EdgeInsets.all(16),
      backgroundColor: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      child: child,
    );
  }
}
