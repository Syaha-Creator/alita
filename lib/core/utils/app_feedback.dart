import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppFeedbackType { success, error, info, warning }

/// Centralized feedback: overlay toast dengan animasi masuk dan progress line
/// yang menyusut untuk menunjukkan sisa waktu.
class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _current;

  static void plain(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
    bool floating = true,
  }) {
    _showOverlay(
      context,
      message: message,
      type: AppFeedbackType.info,
      duration: duration,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    required AppFeedbackType type,
    Duration duration = const Duration(seconds: 2),
    bool floating = true,
  }) {
    _showOverlay(context, message: message, type: type, duration: duration);
  }

  static void _showOverlay(
    BuildContext context, {
    required String message,
    required AppFeedbackType type,
    required Duration duration,
  }) {
    _current?.remove();
    _current = null;

    final overlay = OverlayEntry(
      builder: (ctx) => _FeedbackOverlay(
        message: message,
        type: type,
        duration: duration,
        onDone: () {
          _current?.remove();
          _current = null;
        },
      ),
    );
    _current = overlay;
    Overlay.of(context).insert(overlay);
  }

  static Color _color(AppFeedbackType type) => switch (type) {
        AppFeedbackType.success => AppColors.success,
        AppFeedbackType.error => AppColors.error,
        AppFeedbackType.info => AppColors.textSecondary,
        AppFeedbackType.warning => AppColors.warning,
      };

  static IconData _icon(AppFeedbackType type) => switch (type) {
        AppFeedbackType.success => Icons.check_circle_rounded,
        AppFeedbackType.error => Icons.error_rounded,
        AppFeedbackType.info => Icons.info_rounded,
        AppFeedbackType.warning => Icons.warning_rounded,
      };
}

class _FeedbackOverlay extends StatefulWidget {
  const _FeedbackOverlay({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDone,
  });

  final String message;
  final AppFeedbackType type;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends State<_FeedbackOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _opacity = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _entryCtrl.forward();

    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _entryCtrl.reverse();
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).padding;
    final color = AppFeedback._color(widget.type);
    final icon = AppFeedback._icon(widget.type);

    return Positioned(
      left: 20,
      right: 20,
      bottom: safe.bottom + 24,
      child: SlideTransition(
        position: _slide,
        child: FadeTransition(
          opacity: _opacity,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        Icon(icon, color: AppColors.onPrimary, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: AppColors.onPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ProgressLine(duration: widget.duration),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Garis progress yang menyusut dari penuh ke kosong selama [duration].
class _ProgressLine extends StatefulWidget {
  const _ProgressLine({required this.duration});

  final Duration duration;

  @override
  State<_ProgressLine> createState() => _ProgressLineState();
}

class _ProgressLineState extends State<_ProgressLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _value;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _value = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.linear),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _value,
      builder: (context, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * _value.value;
            return Container(
              height: 3,
              color: Colors.white.withValues(alpha: 0.35),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: width,
                    child: Container(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
