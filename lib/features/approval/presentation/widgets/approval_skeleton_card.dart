import 'package:flutter/material.dart';

/// Skeleton loading card untuk approval monitoring
class ApprovalSkeletonCard extends StatefulWidget {
  const ApprovalSkeletonCard({super.key});

  @override
  State<ApprovalSkeletonCard> createState() => _ApprovalSkeletonCardState();
}

class _ApprovalSkeletonCardState extends State<ApprovalSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header skeleton
                Row(
                  children: [
                    _buildSkeletonContainer(
                      width: 80,
                      height: 20,
                      opacity: _animation.value,
                      color: colorScheme.primary.withOpacity(0.1),
                    ),
                    const Spacer(),
                    _buildSkeletonContainer(
                      width: 60,
                      height: 24,
                      opacity: _animation.value,
                      color: colorScheme.secondary.withOpacity(0.1),
                      borderRadius: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title skeleton
                _buildSkeletonContainer(
                  width: double.infinity,
                  height: 18,
                  opacity: _animation.value,
                  color: colorScheme.onSurface.withOpacity(0.1),
                ),
                const SizedBox(height: 8),

                // Subtitle skeleton
                _buildSkeletonContainer(
                  width: 200,
                  height: 14,
                  opacity: _animation.value,
                  color: colorScheme.onSurface.withOpacity(0.05),
                ),
                const SizedBox(height: 16),

                // Content rows skeleton
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonContainer(
                            width: 60,
                            height: 12,
                            opacity: _animation.value,
                            color: colorScheme.onSurface.withOpacity(0.05),
                          ),
                          const SizedBox(height: 4),
                          _buildSkeletonContainer(
                            width: 100,
                            height: 14,
                            opacity: _animation.value,
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSkeletonContainer(
                            width: 80,
                            height: 12,
                            opacity: _animation.value,
                            color: colorScheme.onSurface.withOpacity(0.05),
                          ),
                          const SizedBox(height: 4),
                          _buildSkeletonContainer(
                            width: 120,
                            height: 14,
                            opacity: _animation.value,
                            color: colorScheme.onSurface.withOpacity(0.1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Bottom row skeleton
                Row(
                  children: [
                    _buildSkeletonContainer(
                      width: 40,
                      height: 12,
                      opacity: _animation.value,
                      color: colorScheme.onSurface.withOpacity(0.05),
                    ),
                    const SizedBox(width: 8),
                    _buildSkeletonContainer(
                      width: 80,
                      height: 12,
                      opacity: _animation.value,
                      color: colorScheme.onSurface.withOpacity(0.05),
                    ),
                    const Spacer(),
                    _buildSkeletonContainer(
                      width: 24,
                      height: 24,
                      opacity: _animation.value,
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkeletonContainer({
    required double width,
    required double height,
    required double opacity,
    required Color color,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color.withOpacity(opacity),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Skeleton loading untuk approval list
class ApprovalSkeletonList extends StatelessWidget {
  final int itemCount;

  const ApprovalSkeletonList({
    super.key,
    this.itemCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return ApprovalSkeletonCard();
      },
    );
  }
}
