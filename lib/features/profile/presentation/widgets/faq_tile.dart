import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Animated expandable FAQ tile with search highlight support.
class FaqTile extends StatefulWidget {
  const FaqTile({
    required this.question,
    required this.answer,
    required this.isExpanded,
    required this.onExpansionChanged,
    this.highlight,
    super.key,
  });

  final String question;
  final String answer;
  final bool isExpanded;
  final ValueChanged<bool> onExpansionChanged;
  final String? highlight;

  @override
  State<FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<FaqTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _size;
  late final Animation<double> _fade;
  late final Animation<double> _turns;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 260),
    );

    final curve =
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
    _size = curve;
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 1, curve: Curves.easeOut),
      reverseCurve: const Interval(0, 0.85, curve: Curves.easeIn),
    );
    _turns = Tween<double>(begin: 0, end: 0.5).animate(curve);

    if (widget.isExpanded) _controller.value = 1;
  }

  @override
  void didUpdateWidget(covariant FaqTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isExpanded != widget.isExpanded) {
      widget.isExpanded ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.isExpanded ? AppColors.accentBorder : AppColors.border,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => widget.onExpansionChanged(!widget.isExpanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildHighlightedText(
                          widget.question,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      RotationTransition(
                        turns: _turns,
                        child: Icon(
                          Icons.expand_more_rounded,
                          size: 22,
                          color: widget.isExpanded
                              ? AppColors.accent
                              : AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  ClipRect(
                    child: SizeTransition(
                      sizeFactor: _size,
                      axisAlignment: -1,
                      child: FadeTransition(
                        opacity: _fade,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: _buildHighlightedText(
                              widget.answer,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, {required TextStyle style}) {
    final query = widget.highlight?.toLowerCase() ?? '';
    if (query.isEmpty) return Text(text, style: style);

    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    var start = 0;

    while (true) {
      final idx = lower.indexOf(query, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: const TextStyle(
          backgroundColor: AppColors.warningLight,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ));
      start = idx + query.length;
    }

    return RichText(text: TextSpan(style: style, children: spans));
  }
}
