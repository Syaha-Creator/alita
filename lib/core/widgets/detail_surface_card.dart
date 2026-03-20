import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
    return Semantics(
      container: true,
      child: SectionCard(
      padding: padding ?? const EdgeInsets.all(16),
      backgroundColor: AppColors.surface,
      boxShadow: const [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
      child: child,
      ),
    );
  }
}
